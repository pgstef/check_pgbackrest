#!/usr/bin/env bash
cd "$(dirname "$0")"

usage() { 
    echo "Usage: `basename $0` [-p <local|remote>]" 1>&2; 
    exit 1; 
}

while getopts "p:" o; do
    case "${o}" in
        p)
            p=${OPTARG}
            ;;
        *)
            usage
            ;;
    esac
done
shift $((OPTIND-1))

# vars
SPROFILE=${p}
PGUSER=postgres
LOOP_NB=10

if [ -e "../configuration.profile" ]; then
    echo "--source generated configuration profile"
    source ../configuration.profile
fi

if [ "$SPROFILE" != "local" ] && [ "$SPROFILE" != "remote" ]; then
    usage
fi

echo "SPROFILE = $SPROFILE"
echo "PGUSER = $PGUSER"
echo "LOOP_NB = $LOOP_NB"

# run
echo "--Create test-checksums setup"
sudo -iu $PGUSER dropdb --if-exists test-checksums
sudo -iu $PGUSER createdb test-checksums
sudo -iu $PGUSER psql -d test-checksums -c "CREATE TABLE t1 (id int);INSERT INTO t1 VALUES (1);"

echo "--Take a full backup"
if [ "$SPROFILE" = "local" ]; then
    sudo -iu $PGUSER pgbackrest --stanza=my_stanza --type=full backup
else
    sudo -iu $PGUSER ssh backup-srv "pgbackrest --stanza=my_stanza --type=full backup"
fi
sudo -iu $PGUSER pgbackrest --stanza=my_stanza info

echo "--Corrupt some data file"
yum install --nogpgcheck --quiet -y -e 0 vim-common
FILE_TO_EDIT=`sudo -iu $PGUSER psql -A -t -d test-checksums -c "SELECT current_setting('data_directory') || '/' || pg_relation_filepath('t1');"`
echo "33" |xxd > $FILE_TO_EDIT

echo "--Take an incremental backup - checksum WARNING should be reported!"
if [ "$SPROFILE" = "local" ]; then
    sudo -iu $PGUSER pgbackrest --stanza=my_stanza --type=incr backup
else
    sudo -iu $PGUSER ssh backup-srv "pgbackrest --stanza=my_stanza --type=incr backup"
fi
sudo -iu $PGUSER pgbackrest --stanza=my_stanza info

echo "--Setup asynchronous archiving"
# archive_command setup
cat <<'EOS' | "/usr/bin/psql" -U ${PGUSER} -d postgres
ALTER SYSTEM SET "archive_command" TO 'pgbackrest --stanza=my_stanza archive-push %p --archive-async --archive-push-queue-max=100MB';
SELECT pg_reload_conf();
EOS

echo "--Generate $LOOP_NB archives"
LOOPS=($(seq 1 1 $LOOP_NB))
FIRST_VALUE=${LOOPS[0]}
LAST_VALUE=${LOOPS[-1]}
sudo -iu $PGUSER psql -d test-checksums -c "DROP TABLE t1; CREATE TABLE t1 (id int);"
for i in "${LOOPS[@]}"
do
    echo "Run ... $i / $LOOP_NB"
    sudo -iu $PGUSER psql -d test-checksums -c "INSERT INTO t1 VALUES (1);SELECT pg_switch_wal();"
    sleep 1
done