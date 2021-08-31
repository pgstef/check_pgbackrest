#!/usr/bin/env bash
set -o nounset
cd "$(dirname "$0")"

# vars
PLUGIN_PATH=/usr/lib64/nagios/plugins
RESULTS_DIR=/tmp/results
SKIP_INIT=false

usage() {
    echo "Usage:"
    echo "    -s                          Skip backups initialization step."
    echo "    -P <path>                   Change check_pgbackrest plugin path."
    echo "    -p <local|remote>           Use local or remote profile."
}

while getopts "sP:p:" o; do
    case "${o}" in
        s)
            SKIP_INIT=true
            ;;
        P)
            PLUGIN_PATH=${OPTARG}
            ;;
        p)
            SCRIPT_PROFILE=${OPTARG}
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
echo "SKIP_INIT = $SKIP_INIT"
echo "PLUGIN_PATH = $PLUGIN_PATH"
echo "SCRIPT_PROFILE = $SCRIPT_PROFILE"
echo "PGBIN = $PGBIN"
echo "PGDATABASE = $PGDATABASE"
echo "PGUNIXSOCKET = $PGUNIXSOCKET"
echo "PGUSER = $PGUSER"
echo "STANZA = $STANZA"
if [ ! -z "$PGBR_HOST" ]; then
    echo "PGBR_USER = $PGBR_USER"
    echo "PGBR_HOST = $PGBR_HOST"
    PGBR_HOST=(`$PYTHON -c "print(' '.join($PGBR_HOST))"`)
fi
echo "PGBR_REPO_TYPE = $PGBR_REPO_TYPE"
REPO=""
if [ "$PGBR_REPO_TYPE" = "multi" ]; then
    REPO="--repo=1"
    echo "...multi repo support, defaulting to repo1"
fi

if [ ! -d $RESULTS_DIR ]; then
     mkdir $RESULTS_DIR
fi

## Tests
# Initiate backups (full, diff, incr)
if ! $SKIP_INIT; then
    echo "...Initiate backups (full, diff, incr)"
    if [ "$SCRIPT_PROFILE" = "local" ]; then
        sudo -iu $PGUSER pgbackrest --stanza=$STANZA $REPO backup --type=full --repo1-retention-full=1
        sudo -iu $PGUSER pgbackrest --stanza=$STANZA $REPO backup --type=diff
        sudo -iu $PGUSER pgbackrest --stanza=$STANZA $REPO backup --type=incr
    else
        sudo -iu $PGUSER ssh ${SSH_ARGS} ${PGBR_USER}@${PGBR_HOST} "pgbackrest --stanza=$STANZA $REPO backup --type=full --repo1-retention-full=1"
        sudo -iu $PGUSER ssh ${SSH_ARGS} ${PGBR_USER}@${PGBR_HOST} "pgbackrest --stanza=$STANZA $REPO backup --type=diff"
        sudo -iu $PGUSER ssh ${SSH_ARGS} ${PGBR_USER}@${PGBR_HOST} "pgbackrest --stanza=$STANZA $REPO backup --type=incr"
    fi
fi

# --list
echo "--list"
$PLUGIN_PATH/check_pgbackrest --list | tee $RESULTS_DIR/list.out

# --version
echo "--version"
$PLUGIN_PATH/check_pgbackrest --version


# --service=retention --retention-full
echo "--service=retention --retention-full"
$PLUGIN_PATH/check_pgbackrest --prefix="sudo -u $PGUSER" --stanza=$STANZA $REPO --service=retention --retention-full=1 --output=human
$PLUGIN_PATH/check_pgbackrest --prefix="sudo -u $PGUSER" --stanza=$STANZA $REPO --service=retention --retention-full=1 --output=prtg
$PLUGIN_PATH/check_pgbackrest --prefix="sudo -u $PGUSER" --stanza=$STANZA $REPO --service=retention --retention-full=1 | cut -f1 -d"|" > $RESULTS_DIR/retention-full.out
echo

# --service=retention --retention-age
echo "--service=retention --retention-age"
$PLUGIN_PATH/check_pgbackrest --prefix="sudo -u $PGUSER" --stanza=$STANZA $REPO --service=retention --retention-age=1h --output=human
$PLUGIN_PATH/check_pgbackrest --prefix="sudo -u $PGUSER" --stanza=$STANZA $REPO --service=retention --retention-age=1h | cut -f1 -d"|" > $RESULTS_DIR/retention-age.out

# --service=retention --retention-age-to-full
echo "--service=retention --retention-age-to-full"
$PLUGIN_PATH/check_pgbackrest --prefix="sudo -u $PGUSER" --stanza=$STANZA $REPO --service=retention --retention-age-to-full=1h --output=human
$PLUGIN_PATH/check_pgbackrest --prefix="sudo -u $PGUSER" --stanza=$STANZA $REPO --service=retention --retention-age-to-full=1h | cut -f1 -d"|" > $RESULTS_DIR/retention-age-to-full.out

# --service=retention fail
echo "--service=retention fail"
sudo -iu $PGUSER $PGBIN/psql -h $PGUNIXSOCKET -d $PGDATABASE -c "SELECT pg_sleep(2);" > /dev/null 2>&1
$PLUGIN_PATH/check_pgbackrest --prefix="sudo -u $PGUSER" --stanza=$STANZA $REPO --service=retention --retention-full=2 --retention-age=1s --retention-age-to-full=1s --output=human
$PLUGIN_PATH/check_pgbackrest --prefix="sudo -u $PGUSER" --stanza=$STANZA $REPO --service=retention --retention-full=2 --retention-age=1s --retention-age-to-full=1s | cut -f1 -d"|" > $RESULTS_DIR/retention-fail.out

# --service=archives
echo "--service=archives"
sudo -iu $PGUSER $PGBIN/psql -h $PGUNIXSOCKET -d $PGDATABASE -c "SELECT pg_create_restore_point('generate WAL');" > /dev/null 2>&1
sudo -iu $PGUSER $PGBIN/psql -h $PGUNIXSOCKET -d $PGDATABASE -c "SELECT pg_switch_xlog();" > /dev/null 2>&1
sudo -iu $PGUSER $PGBIN/psql -h $PGUNIXSOCKET -d $PGDATABASE -c "SELECT pg_switch_wal();" > /dev/null 2>&1
sudo -iu $PGUSER $PGBIN/psql -h $PGUNIXSOCKET -d $PGDATABASE -c "SELECT pg_sleep(1);" > /dev/null 2>&1
$PLUGIN_PATH/check_pgbackrest --prefix="sudo -u $PGUSER" --stanza=$STANZA $REPO --service=archives --output=human
$PLUGIN_PATH/check_pgbackrest --prefix="sudo -u $PGUSER" --stanza=$STANZA $REPO --service=archives --output=prtg
$PLUGIN_PATH/check_pgbackrest --prefix="sudo -u $PGUSER" --stanza=$STANZA $REPO --service=archives | cut -f1 -d"-" > $RESULTS_DIR/archives-ok.out
echo

# --service=archives --ignore-archived-before
echo "--service=archives --ignore-archived-before"
sudo -iu $PGUSER $PGBIN/psql -h $PGUNIXSOCKET -d $PGDATABASE -c "SELECT pg_sleep(2);" > /dev/null 2>&1
$PLUGIN_PATH/check_pgbackrest --prefix="sudo -u $PGUSER" --stanza=$STANZA $REPO --service=archives --ignore-archived-before=1s > $RESULTS_DIR/archives-ignore-before.out

# --service=archives --ignore-archived-after
echo "--service=archives --ignore-archived-after"
$PLUGIN_PATH/check_pgbackrest --prefix="sudo -u $PGUSER" --stanza=$STANZA $REPO --service=archives --ignore-archived-after=1h > $RESULTS_DIR/archives-ignore-after.out

# --service=archives --latest-archive-age-alert
echo "--service=archives --latest-archive-age-alert"
sudo -iu $PGUSER $PGBIN/psql -h $PGUNIXSOCKET -d $PGDATABASE -c "SELECT pg_sleep(2);" > /dev/null 2>&1
$PLUGIN_PATH/check_pgbackrest --prefix="sudo -u $PGUSER" --stanza=$STANZA $REPO --service=archives --latest-archive-age-alert=1h | cut -f1 -d"-" > $RESULTS_DIR/archives-age-alert-ok.out
$PLUGIN_PATH/check_pgbackrest --prefix="sudo -u $PGUSER" --stanza=$STANZA $REPO --service=archives --latest-archive-age-alert=1s --output=human
$PLUGIN_PATH/check_pgbackrest --prefix="sudo -u $PGUSER" --stanza=$STANZA $REPO --service=archives --latest-archive-age-alert=1s | cut -f1 -d"-" > $RESULTS_DIR/archives-age-alert-ko.out

# --service=archives --max-archives-check-number
echo "--service=archives --max-archives-check-number"
$PLUGIN_PATH/check_pgbackrest --prefix="sudo -u $PGUSER" --stanza=$STANZA $REPO --service=archives --max-archives-check-number=1 > $RESULTS_DIR/archives-max-archives-check-ko.out 2>&1

## Results
diff -abB expected/ $RESULTS_DIR/ > /tmp/regression.diffs
if [ $(wc -l < /tmp/regression.diffs) -gt 0 ]; then
     cat /tmp/regression.diffs
     exit 1
fi
exit 0
