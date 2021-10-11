#!/usr/bin/env bash
set -o errexit
set -o nounset
cd "$(dirname "$0")"

EXTENDED_ACTIVITY=false
usage() { 
    echo "Usage:"
    echo "    -s <scale>"
    echo "    -a <activity_time>"
    echo "    -p <local|remote>"
    echo "    -e (extended activity)"
}

while getopts "s:a:p:e" o; do
    case "${o}" in
        s)
            SCALE=${OPTARG}
            ;;
        a)
            ACTIVITY_TIME=${OPTARG}
            ;;
        p)
            SCRIPT_PROFILE=${OPTARG}
            ;;
        e)
            EXTENDED_ACTIVITY=true
            ;;
        *)
            usage 1>&2
            exit 1
            ;;
    esac
done
shift $((OPTIND-1))

if [ -z "$SCRIPT_PROFILE" ]; then
    SCRIPT_PROFILE="local"
    if [ ! -z $PGBR_HOST ]; then
        SCRIPT_PROFILE="remote"
    fi
fi

if [ "$SCRIPT_PROFILE" != "local" ] && [ "$SCRIPT_PROFILE" != "remote" ]; then
    usage
fi

PYTHON="python3"
command -v $PYTHON >/dev/null 2>&1 || { PYTHON="python"; }
SSH_ARGS='-o ConnectTimeout=10 -o BatchMode=yes -o StrictHostKeyChecking=no'
echo "SCALE = $SCALE"
echo "ACTIVITY_TIME = $ACTIVITY_TIME seconds"
echo "SCRIPT_PROFILE = $SCRIPT_PROFILE"
echo "PGBIN = $PGBIN"
echo "PGDATABASE = $PGDATABASE"
echo "PGSVC = $PGSVC"
echo "PGUNIXSOCKET = $PGUNIXSOCKET"
echo "PGUSER = $PGUSER"
echo "STANZA = $STANZA"
if [ ! -z "$PGBR_HOST" ]; then
    echo "PGBR_USER = $PGBR_USER"
    echo "PGBR_HOST = $PGBR_HOST"
    PGBR_HOST=(`$PYTHON -c "print(' '.join($PGBR_HOST))"`)
fi
if [ ! -z "$PGBR_STANDBIES" ]; then
    echo "PGBR_STANDBIES = $PGBR_STANDBIES"
    PGBR_STANDBIES=(`$PYTHON -c "print(' '.join($PGBR_STANDBIES))"`)
fi
echo "PGBR_REPO_TYPE = $PGBR_REPO_TYPE"
REPO=""
if [ "$PGBR_REPO_TYPE" = "multi" ]; then
    REPO="--repo=1"
    echo "...multi repo support, defaulting to repo1"
fi

# run
echo "-------------------PROCESS START-------------------"
echo "--Create pgbench setup"
sudo -iu $PGUSER $PGBIN/dropdb -h $PGUNIXSOCKET --if-exists bench
sudo -iu $PGUSER $PGBIN/createdb -h $PGUNIXSOCKET bench
sudo -iu $PGUSER $PGBIN/pgbench -h $PGUNIXSOCKET -i -s $SCALE --quiet --foreign-keys bench

echo "--Take a full backup"
if [ "$SCRIPT_PROFILE" = "local" ]; then
    sudo -iu $PGUSER pgbackrest --stanza=$STANZA $REPO --type=full backup
else
    sudo -iu $PGUSER ssh ${SSH_ARGS} ${PGBR_USER}@${PGBR_HOST} "pgbackrest --stanza=$STANZA $REPO --type=full backup"
fi
sudo -iu $PGUSER pgbackrest --stanza=$STANZA $REPO info

echo "--Simulate $ACTIVITY_TIME sec activity"
sudo -iu $PGUSER $PGBIN/pgbench -h $PGUNIXSOCKET -T $ACTIVITY_TIME bench

echo "--Take an incremental backup"
if [ "$SCRIPT_PROFILE" = "local" ]; then
    sudo -iu $PGUSER pgbackrest --stanza=$STANZA $REPO --type=incr backup
else
    sudo -iu $PGUSER ssh ${SSH_ARGS} ${PGBR_USER}@${PGBR_HOST} "pgbackrest --stanza=$STANZA $REPO --type=incr backup"
fi
sudo -iu $PGUSER pgbackrest --stanza=$STANZA $REPO info

echo "--Simulate $ACTIVITY_TIME sec activity"
sudo -iu $PGUSER $PGBIN/pgbench -h $PGUNIXSOCKET -T $ACTIVITY_TIME bench

echo "--Take a full backup to test the purge action"
if [ "$SCRIPT_PROFILE" = "local" ]; then
    sudo -iu $PGUSER pgbackrest --stanza=$STANZA $REPO --type=full backup
else
    sudo -iu $PGUSER ssh ${SSH_ARGS} ${PGBR_USER}@${PGBR_HOST} "pgbackrest --stanza=$STANZA $REPO --type=full backup"
fi
sudo -iu $PGUSER pgbackrest --stanza=$STANZA $REPO info

echo "--Simulate $ACTIVITY_TIME sec activity"
sudo -iu $PGUSER $PGBIN/pgbench -h $PGUNIXSOCKET -T $ACTIVITY_TIME bench

echo "--Create restore point RP1 and get latest pgbench history time"
sudo -iu $PGUSER $PGBIN/psql -h $PGUNIXSOCKET -d $PGDATABASE -c "select pg_create_restore_point('RP1');"
sudo -iu $PGUSER $PGBIN/psql -h $PGUNIXSOCKET -d bench -c 'SELECT max(mtime) FROM pgbench_history;'

echo "--Simulate $ACTIVITY_TIME sec activity and get latest pgbench history time"
sudo -iu $PGUSER $PGBIN/pgbench -h $PGUNIXSOCKET -T $ACTIVITY_TIME bench
sudo -iu $PGUSER $PGBIN/psql -h $PGUNIXSOCKET -d bench -c 'SELECT max(mtime) FROM pgbench_history;'

echo "--Restore RP1 restore point and get latest pgbench history time"
systemctl stop $PGSVC
sudo -iu $PGUSER pgbackrest restore --stanza=$STANZA $REPO --delta --type=name --target=RP1 --target-action=promote
systemctl start $PGSVC
systemctl status $PGSVC

echo "--Wait while pg_is_in_recovery"
while [ `sudo -iu $PGUSER $PGBIN/psql -h $PGUNIXSOCKET -d $PGDATABASE -c 'SELECT pg_is_in_recovery();' -A -t` = "t" ]
do
    echo "wait..."
    sleep 5
done
sudo -iu $PGUSER $PGBIN/psql -h $PGUNIXSOCKET -d bench -c 'SELECT max(mtime) FROM pgbench_history;'

echo "--Resync standby server(s)"
echo "----Take incremental backup"
if [ "$SCRIPT_PROFILE" = "local" ]; then
    sudo -iu $PGUSER pgbackrest --stanza=$STANZA $REPO --type=incr backup
else
    sudo -iu $PGUSER ssh ${SSH_ARGS} ${PGBR_USER}@${PGBR_HOST} "pgbackrest --stanza=$STANZA $REPO --type=incr backup"
fi

for i in "${PGBR_STANDBIES[@]}"; do
    echo "----Restore on standby server - $i"
    ssh ${SSH_ARGS} "$i" "systemctl stop $PGSVC"
    ssh ${SSH_ARGS} "$i" "sudo -iu $PGUSER pgbackrest --stanza=$STANZA $REPO --reset-pg2-host --type=standby restore"
    ssh ${SSH_ARGS} "$i" "systemctl start $PGSVC"
done

echo "----Wait until at least 1 standby is replicated"
while [ `sudo -iu $PGUSER $PGBIN/psql -h $PGUNIXSOCKET -d $PGDATABASE -At -c "SELECT count(*) FROM pg_stat_replication;"` -lt 1 ]
do
    echo "wait..."
    sleep 5
done
sudo -iu $PGUSER $PGBIN/psql -h $PGUNIXSOCKET -d $PGDATABASE -x -c "SELECT * FROM pg_stat_replication;"

echo "--Simulate $ACTIVITY_TIME sec activity to get archives on different time-lines"
sudo -iu $PGUSER $PGBIN/pgbench -h $PGUNIXSOCKET -T $ACTIVITY_TIME bench
sudo -iu $PGUSER pgbackrest --stanza=$STANZA $REPO info

if $EXTENDED_ACTIVITY; then
    echo "--Create test-checksums setup"
    sudo -iu $PGUSER $PGBIN/dropdb -h $PGUNIXSOCKET --if-exists test-checksums
    sudo -iu $PGUSER $PGBIN/createdb -h $PGUNIXSOCKET test-checksums
    sudo -iu $PGUSER $PGBIN/psql -h $PGUNIXSOCKET -d test-checksums -c "CREATE TABLE t1 (id int);INSERT INTO t1 VALUES (1);"
    sudo -iu $PGUSER $PGBIN/psql -h $PGUNIXSOCKET -d $PGDATABASE -c "CHECKPOINT;"
    FILE_TO_EDIT=`sudo -iu $PGUSER $PGBIN/psql -h $PGUNIXSOCKET -d test-checksums -A -t -c "SELECT current_setting('data_directory') || '/' || pg_relation_filepath('t1');"`
    echo "FILE_TO_EDIT=$FILE_TO_EDIT"
    echo "33" |xxd > $FILE_TO_EDIT

    echo "--Take an incremental backup"
    if [ "$SCRIPT_PROFILE" = "local" ]; then
        sudo -iu $PGUSER pgbackrest --stanza=$STANZA $REPO --type=incr backup
    else
        sudo -iu $PGUSER ssh ${SSH_ARGS} ${PGBR_USER}@${PGBR_HOST} "pgbackrest --stanza=$STANZA $REPO --type=incr backup"
    fi
    sudo -iu $PGUSER pgbackrest --stanza=$STANZA $REPO info
fi
echo "-------------------PROCESS END-------------------"
