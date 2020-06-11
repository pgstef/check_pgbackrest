#!/usr/bin/env bash
cd "$(dirname "$0")"

usage() { 
    echo "Usage: `basename $0` [-s <scale>] [-a <activity_time>] [-p <local|remote>]" 1>&2; 
    exit 1; 
}

while getopts ":s:a:p:" o; do
    case "${o}" in
        s)
            s=${OPTARG}
            ;;
        a)
            a=${OPTARG}
            ;;
        p)
            p=${OPTARG}
            if [ "$p" != "local" ] && [ "$p" != "remote" ]; then
                usage
            fi
            ;;
        *)
            usage
            ;;
    esac
done
shift $((OPTIND-1))

if [ -z "${s}" ] || [ -z "${a}" ] || [ -z "${p}" ]; then
    usage
fi

# vars
SCALE=${s}
ACTIVITY_TIME=${a}
PROFILE=${p}
PGVER=12

echo "SCALE = $SCALE"
echo "ACTIVITY_TIME = $ACTIVITY_TIME seconds"
echo "PROFILE = $PROFILE"
echo "PGVER = $PGVER"

# run
echo "--Create pgbench setup"
sudo -iu postgres dropdb --if-exists bench
sudo -iu postgres createdb bench
sudo -iu postgres pgbench -i -s $SCALE --quiet --foreign-keys bench

echo "--Take a full backup"
if [ "$PROFILE" = "local" ]; then
    sudo -iu postgres pgbackrest --stanza=my_stanza --type=full backup
else
    sudo -iu postgres ssh backup-srv "pgbackrest --stanza=my_stanza --type=full backup"
fi
sudo -iu postgres pgbackrest --stanza=my_stanza info

echo "--Simulate $ACTIVITY_TIME sec activity"
sudo -iu postgres pgbench -T $ACTIVITY_TIME bench

echo "--Take an incremental backup"
if [ "$PROFILE" = "local" ]; then
    sudo -iu postgres pgbackrest --stanza=my_stanza --type=incr backup
else
    sudo -iu postgres ssh backup-srv "pgbackrest --stanza=my_stanza --type=incr backup"
fi
sudo -iu postgres pgbackrest --stanza=my_stanza info

echo "--Simulate $ACTIVITY_TIME sec activity"
sudo -iu postgres pgbench -T $ACTIVITY_TIME bench

echo "--Take a full backup to test the purge action"
if [ "$PROFILE" = "local" ]; then
    sudo -iu postgres pgbackrest --stanza=my_stanza --type=full backup
else
    sudo -iu postgres ssh backup-srv "pgbackrest --stanza=my_stanza --type=full backup"
fi
sudo -iu postgres pgbackrest --stanza=my_stanza info

echo "--Simulate $ACTIVITY_TIME sec activity"
sudo -iu postgres pgbench -T $ACTIVITY_TIME bench

echo "--Create restore point RP1 and get latest pgbench history time"
sudo -iu postgres psql -c "select pg_create_restore_point('RP1');"
sudo -iu postgres psql -d bench -c 'SELECT max(mtime) FROM pgbench_history;'

echo "--Simulate $ACTIVITY_TIME sec activity and get latest pgbench history time"
sudo -iu postgres pgbench -T $ACTIVITY_TIME bench
sudo -iu postgres psql -d bench -c 'SELECT max(mtime) FROM pgbench_history;'

echo "--Restore RP1 restore point and get latest pgbench history time"
systemctl stop "postgresql-${PGVER}"
sudo -iu postgres pgbackrest restore --stanza=my_stanza --delta --type=name --target=RP1 --target-action=promote
systemctl start "postgresql-${PGVER}"
systemctl status "postgresql-${PGVER}"

echo "--Wait while pg_is_in_recovery"
while [ `sudo -iu postgres psql -c 'SELECT pg_is_in_recovery();' -A -t` = "t" ]
do
    echo "wait..."
    sleep 5
done
sudo -iu postgres psql -d bench -c 'SELECT max(mtime) FROM pgbench_history;'

if [ "$PROFILE" = "remote" ]; then
    echo "--Resync standby server"
    echo "----Take incremental backup"
    sudo -iu postgres ssh backup-srv "pgbackrest --stanza=my_stanza --type=incr backup"

    echo "----Restore it on standby server"
    ssh backup-srv "systemctl stop postgresql-${PGVER}"
    sudo -iu postgres ssh backup-srv "pgbackrest --stanza=my_stanza --config=/etc/pgbackrest-restore.conf --type=standby restore"
    ssh backup-srv "systemctl start postgresql-${PGVER}"

    echo "----Wait until standby is replicated"
    while [ `sudo -iu postgres psql -At -c "SELECT count(*) FROM pg_stat_replication;"` -lt 1 ]
    do
        echo "wait..."
        sleep 5
    done
    sudo -iu postgres psql -x -c "SELECT * FROM pg_stat_replication;"
fi

echo "--Simulate $ACTIVITY_TIME sec activity to get archives on different time-lines"
sudo -iu postgres pgbench -T $ACTIVITY_TIME bench
sudo -iu postgres pgbackrest --stanza=my_stanza info