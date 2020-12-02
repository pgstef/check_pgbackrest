#!/usr/bin/env bash
cd "$(dirname "$0")"

usage() { 
    echo "Usage: `basename $0` [-s <scale>] [-a <activity_time>] [-p <local|remote>]" 1>&2; 
    exit 1; 
}

while getopts "s:a:p:" o; do
    case "${o}" in
        s)
            s=${OPTARG}
            ;;
        a)
            a=${OPTARG}
            ;;
        p)
            p=${OPTARG}
            ;;
        *)
            usage
            ;;
    esac
done
shift $((OPTIND-1))

if [ -z "${s}" ] || [ -z "${a}" ]; then
    usage
fi

# vars
SCALE=${s}
ACTIVITY_TIME=${a}
SPROFILE=${p}
PGVER=13
PGUSER=postgres
PGSVC="postgresql-$PGVER"

if [ -e "../configuration.profile" ]; then
    echo "--source generated configuration profile"
    source ../configuration.profile
fi

if [ "$SPROFILE" != "local" ] && [ "$SPROFILE" != "remote" ]; then
    usage
fi

echo "SCALE = $SCALE"
echo "ACTIVITY_TIME = $ACTIVITY_TIME seconds"
echo "SPROFILE = $SPROFILE"
echo "PGVER = $PGVER"
echo "PGUSER = $PGUSER"
echo "PGSVC = $PGSVC"

# run
echo "--Create pgbench setup"
sudo -iu $PGUSER dropdb --if-exists bench
sudo -iu $PGUSER createdb bench
sudo -iu $PGUSER pgbench -i -s $SCALE --quiet --foreign-keys bench

echo "--Take a full backup"
if [ "$SPROFILE" = "local" ]; then
    sudo -iu $PGUSER pgbackrest --stanza=my_stanza --type=full backup
else
    sudo -iu $PGUSER ssh backup-srv "pgbackrest --stanza=my_stanza --type=full backup"
fi
sudo -iu $PGUSER pgbackrest --stanza=my_stanza info

echo "--Simulate $ACTIVITY_TIME sec activity"
sudo -iu $PGUSER pgbench -T $ACTIVITY_TIME bench

echo "--Take an incremental backup"
if [ "$SPROFILE" = "local" ]; then
    sudo -iu $PGUSER pgbackrest --stanza=my_stanza --type=incr backup
else
    sudo -iu $PGUSER ssh backup-srv "pgbackrest --stanza=my_stanza --type=incr backup"
fi
sudo -iu $PGUSER pgbackrest --stanza=my_stanza info

echo "--Simulate $ACTIVITY_TIME sec activity"
sudo -iu $PGUSER pgbench -T $ACTIVITY_TIME bench

echo "--Take a full backup to test the purge action"
if [ "$SPROFILE" = "local" ]; then
    sudo -iu $PGUSER pgbackrest --stanza=my_stanza --type=full backup
else
    sudo -iu $PGUSER ssh backup-srv "pgbackrest --stanza=my_stanza --type=full backup"
fi
sudo -iu $PGUSER pgbackrest --stanza=my_stanza info

echo "--Simulate $ACTIVITY_TIME sec activity"
sudo -iu $PGUSER pgbench -T $ACTIVITY_TIME bench

echo "--Create restore point RP1 and get latest pgbench history time"
sudo -iu $PGUSER psql -d postgres -c "select pg_create_restore_point('RP1');"
sudo -iu $PGUSER psql -d bench -c 'SELECT max(mtime) FROM pgbench_history;'

echo "--Simulate $ACTIVITY_TIME sec activity and get latest pgbench history time"
sudo -iu $PGUSER pgbench -T $ACTIVITY_TIME bench
sudo -iu $PGUSER psql -d bench -c 'SELECT max(mtime) FROM pgbench_history;'

echo "--Restore RP1 restore point and get latest pgbench history time"
systemctl stop $PGSVC
sudo -iu $PGUSER pgbackrest restore --stanza=my_stanza --delta --type=name --target=RP1 --target-action=promote
systemctl start $PGSVC
systemctl status $PGSVC

echo "--Wait while pg_is_in_recovery"
while [ `sudo -iu $PGUSER psql -d postgres -c 'SELECT pg_is_in_recovery();' -A -t` = "t" ]
do
    echo "wait..."
    sleep 5
done
sudo -iu $PGUSER psql -d bench -c 'SELECT max(mtime) FROM pgbench_history;'

if [ "$SPROFILE" = "remote" ]; then
    echo "--Resync standby server"
    echo "----Take incremental backup"
    sudo -iu $PGUSER ssh backup-srv "pgbackrest --stanza=my_stanza --type=incr backup"

    echo "----Restore it on standby server"
    ssh backup-srv "systemctl stop $PGSVC"
    sudo -iu $PGUSER ssh backup-srv "pgbackrest --stanza=my_stanza --reset-pg1-host --type=standby restore"
    ssh backup-srv "systemctl start $PGSVC"

    echo "----Wait until standby is replicated"
    while [ `sudo -iu $PGUSER psql -d postgres -At -c "SELECT count(*) FROM pg_stat_replication;"` -lt 1 ]
    do
        echo "wait..."
        sleep 5
    done
    sudo -iu $PGUSER psql -d postgres -x -c "SELECT * FROM pg_stat_replication;"
fi

echo "--Simulate $ACTIVITY_TIME sec activity to get archives on different time-lines"
sudo -iu $PGUSER pgbench -T $ACTIVITY_TIME bench
sudo -iu $PGUSER pgbackrest --stanza=my_stanza info