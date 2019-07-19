#!/usr/bin/env bash

cd "$(dirname "$0")"
PLUGIN_PATH=/usr/lib64/nagios/plugins
RESULTS_DIR=/tmp/results

# Generate the expected results ?
GENERATE_EXPECTED=false

if $GENERATE_EXPECTED; then
	RESULTS_DIR=expected
fi

if [ ! -d $RESULTS_DIR ]; then
     mkdir $RESULTS_DIR
fi

## Tests
# --list
echo "--list"
$PLUGIN_PATH/check_pgbackrest --list > $RESULTS_DIR/list.out

# --version
echo "--version"
$PLUGIN_PATH/check_pgbackrest --version > $RESULTS_DIR/version.out

# --service=retention missing arg
echo "--service=retention missing arg"
$PLUGIN_PATH/check_pgbackrest --stanza=my_stanza --service=retention > $RESULTS_DIR/retention-missing-arg.out 2>&1

# --service=retention --retention-full
echo "--service=retention --retention-full"
sudo -iu postgres pgbackrest --stanza=my_stanza backup --type=full --repo1-retention-full=1
$PLUGIN_PATH/check_pgbackrest --stanza=my_stanza --service=retention --retention-full=1 | cut -f1 -d"|" > $RESULTS_DIR/retention-full.out

# --service=retention --retention-age
echo "--service=retention --retention-age"
$PLUGIN_PATH/check_pgbackrest --stanza=my_stanza --service=retention --retention-age=1h | cut -f1 -d"|" > $RESULTS_DIR/retention-age.out

# --service=retention fail
echo "--service=retention fail"
sudo -iu postgres psql -c "SELECT pg_sleep(1);" > /dev/null 2>&1
$PLUGIN_PATH/check_pgbackrest --stanza=my_stanza --service=retention --retention-full=2 --retention-age=1s | cut -f1 -d"|" > $RESULTS_DIR/retention-fail.out

# # --service=archives missing arg
echo "--service=archives missing arg"
$PLUGIN_PATH/check_pgbackrest --stanza=my_stanza --service=archives > $RESULTS_DIR/archives-missing-arg.out 2>&1

# # --service=archives --repo-path
echo "--service=archives --repo-path"
sudo -iu postgres psql -c "SELECT pg_switch_xlog();" > /dev/null 2>&1
sudo -iu postgres psql -c "SELECT pg_switch_wal();" > /dev/null 2>&1
$PLUGIN_PATH/check_pgbackrest --stanza=my_stanza --service=archives --repo-path=/repo1/archive --repo-s3 --repo-s3-over-http | cut -f1 -d"-" > $RESULTS_DIR/archives-ok.out

# # --service=archives --ignore-archived-since
echo "--service=archives --ignore-archived-since"
$PLUGIN_PATH/check_pgbackrest --stanza=my_stanza --service=archives --repo-path=/repo1/archive --repo-s3 --repo-s3-over-http --ignore-archived-since=1h > $RESULTS_DIR/archives-ignore-since.out

# # --service=archives --latest-archive-age-alert
echo "--service=archives --latest-archive-age-alert"
$PLUGIN_PATH/check_pgbackrest --stanza=my_stanza --service=archives --repo-path=/repo1/archive --repo-s3 --repo-s3-over-http --latest-archive-age-alert=1h | cut -f1 -d"-" > $RESULTS_DIR/archives-age-alert-ok.out
$PLUGIN_PATH/check_pgbackrest --stanza=my_stanza --service=archives --repo-path=/repo1/archive --repo-s3 --repo-s3-over-http --latest-archive-age-alert=1s | cut -f1 -d"-" > $RESULTS_DIR/archives-age-alert-ko.out

## Results
diff -abB expected/ $RESULTS_DIR/ > /tmp/regression.diffs
if [ $(wc -l < /tmp/regression.diffs) -gt 0 ]; then
     cat /tmp/regression.diffs
fi
