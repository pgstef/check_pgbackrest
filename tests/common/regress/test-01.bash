#!/usr/bin/env bash
cd "$(dirname "$0")"

usage() {
    echo "Usage:"
    echo "    -s                          Skip backups initialization step."
    echo "    -g                          Generate expected results."
    echo "    -P                          Change check_pgbackrest plugin path."
    echo "    -p <local|remote>           Use local or remote profile."
    echo "    -h                          Display this help message."
}

# vars
PLUGIN_PATH=/usr/lib64/nagios/plugins
RESULTS_DIR=/tmp/results
SKIP_INIT=false
GENERATE_EXPECTED=false
SPROFILE=local
PGUSER=postgres

while getopts "sgP:p:h" o; do
    case "${o}" in
        s)
            SKIP_INIT=true
            ;;
        g)
            GENERATE_EXPECTED=true
            ;;
        P)
            PLUGIN_PATH=${OPTARG}
            ;;
        p)
            SPROFILE=${OPTARG}
            ;;
        h )
            usage
            exit 0
            ;;
        *)
            usage 1>&2
            exit 1
            ;;
    esac
done
shift $((OPTIND-1))

if [ -e "../configuration.profile" ]; then
    echo "...Source generated configuration profile"
    source ../configuration.profile
fi

if [ "$SPROFILE" != "local" ] && [ "$SPROFILE" != "remote" ]; then
    usage 1>&2
    exit 1
fi

echo "SKIP_INIT = $SKIP_INIT"
echo "PLUGIN_PATH = $PLUGIN_PATH"
echo "SPROFILE = $SPROFILE"
echo "PGUSER = $PGUSER"

if $GENERATE_EXPECTED; then
    RESULTS_DIR=expected
fi

if [ ! -d $RESULTS_DIR ]; then
     mkdir $RESULTS_DIR
fi

## Tests
# Initiate backups (full, diff, incr)
if ! $SKIP_INIT; then
    echo "...Initiate backups (full, diff, incr)"
    if [ "$SPROFILE" = "local" ]; then
        sudo -iu $PGUSER pgbackrest --stanza=my_stanza backup --type=full --repo1-retention-full=1
        sudo -iu $PGUSER pgbackrest --stanza=my_stanza backup --type=diff
        sudo -iu $PGUSER pgbackrest --stanza=my_stanza backup --type=incr
    else
        sudo -iu $PGUSER ssh backup-srv "pgbackrest --stanza=my_stanza backup --type=full --repo1-retention-full=1"
        sudo -iu $PGUSER ssh backup-srv "pgbackrest --stanza=my_stanza backup --type=diff"
        sudo -iu $PGUSER ssh backup-srv "pgbackrest --stanza=my_stanza backup --type=incr"
    fi
fi

# --list
echo "--list"
$PLUGIN_PATH/check_pgbackrest --list | tee $RESULTS_DIR/list.out

# --version
echo "--version"
$PLUGIN_PATH/check_pgbackrest --version
$PLUGIN_PATH/check_pgbackrest --version | cut -f1 -d"," > $RESULTS_DIR/version.out

# --service=retention --retention-full
echo "--service=retention --retention-full"
$PLUGIN_PATH/check_pgbackrest --stanza=my_stanza --service=retention --retention-full=1 --output=human
$PLUGIN_PATH/check_pgbackrest --stanza=my_stanza --service=retention --retention-full=1 | cut -f1 -d"|" > $RESULTS_DIR/retention-full.out

# --service=retention --retention-age
echo "--service=retention --retention-age"
$PLUGIN_PATH/check_pgbackrest --stanza=my_stanza --service=retention --retention-age=1h --output=human
$PLUGIN_PATH/check_pgbackrest --stanza=my_stanza --service=retention --retention-age=1h | cut -f1 -d"|" > $RESULTS_DIR/retention-age.out

# --service=retention --retention-age-to-full
echo "--service=retention --retention-age-to-full"
$PLUGIN_PATH/check_pgbackrest --stanza=my_stanza --service=retention --retention-age-to-full=1h --output=human
$PLUGIN_PATH/check_pgbackrest --stanza=my_stanza --service=retention --retention-age-to-full=1h | cut -f1 -d"|" > $RESULTS_DIR/retention-age-to-full.out

# --service=retention fail
echo "--service=retention fail"
sudo -iu $PGUSER psql -d postgres -c "SELECT pg_sleep(2);" > /dev/null 2>&1
$PLUGIN_PATH/check_pgbackrest --stanza=my_stanza --service=retention --retention-full=2 --retention-age=1s --retention-age-to-full=1s --output=human
$PLUGIN_PATH/check_pgbackrest --stanza=my_stanza --service=retention --retention-full=2 --retention-age=1s --retention-age-to-full=1s | cut -f1 -d"|" > $RESULTS_DIR/retention-fail.out

# --service=archives
echo "--service=archives"
sudo -iu $PGUSER psql -d postgres -c "SELECT pg_switch_xlog();" > /dev/null 2>&1
sudo -iu $PGUSER psql -d postgres -c "SELECT pg_switch_wal();" > /dev/null 2>&1
sudo -iu $PGUSER psql -d postgres -c "SELECT pg_sleep(1);" > /dev/null 2>&1
$PLUGIN_PATH/check_pgbackrest --stanza=my_stanza --service=archives --output=human
$PLUGIN_PATH/check_pgbackrest --stanza=my_stanza --service=archives | cut -f1 -d"-" > $RESULTS_DIR/archives-ok.out

# --service=archives --ignore-archived-before
echo "--service=archives --ignore-archived-before"
sudo -iu $PGUSER psql -d postgres -c "SELECT pg_sleep(2);" > /dev/null 2>&1
$PLUGIN_PATH/check_pgbackrest --stanza=my_stanza --service=archives --ignore-archived-before=1s > $RESULTS_DIR/archives-ignore-before.out

# --service=archives --ignore-archived-after
echo "--service=archives --ignore-archived-after"
$PLUGIN_PATH/check_pgbackrest --stanza=my_stanza --service=archives --ignore-archived-after=1h > $RESULTS_DIR/archives-ignore-after.out

# --service=archives --latest-archive-age-alert
echo "--service=archives --latest-archive-age-alert"
sudo -iu $PGUSER psql -d postgres -c "SELECT pg_sleep(2);" > /dev/null 2>&1
$PLUGIN_PATH/check_pgbackrest --stanza=my_stanza --service=archives --latest-archive-age-alert=1h | cut -f1 -d"-" > $RESULTS_DIR/archives-age-alert-ok.out
$PLUGIN_PATH/check_pgbackrest --stanza=my_stanza --service=archives --latest-archive-age-alert=1s --output=human
$PLUGIN_PATH/check_pgbackrest --stanza=my_stanza --service=archives --latest-archive-age-alert=1s | cut -f1 -d"-" > $RESULTS_DIR/archives-age-alert-ko.out

## Results
diff -abB expected/ $RESULTS_DIR/ > /tmp/regression.diffs
if [ $(wc -l < /tmp/regression.diffs) -gt 0 ]; then
     cat /tmp/regression.diffs
fi