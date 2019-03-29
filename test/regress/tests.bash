#!/usr/bin/env bash

cd "$(dirname "$0")"
PLUGIN_PATH=/usr/lib64/nagios/plugins

if [ ! -d results ]; then
     mkdir results
fi

## Tests
# --list
echo "--list"
$PLUGIN_PATH/check_pgbackrest --list > results/list.out

# --version
echo "--version"
$PLUGIN_PATH/check_pgbackrest --version > results/version.out

# --service=retention missing arg
echo "--service=retention missing arg"
$PLUGIN_PATH/check_pgbackrest --stanza=my_stanza --service=retention > results/retention-missing-arg.out 2>&1

# --service=retention --retention-full
echo "--service=retention --retention-full"
sudo -iu postgres pgbackrest --stanza=my_stanza backup --type=full --repo1-retention-full=1
$PLUGIN_PATH/check_pgbackrest --stanza=my_stanza --service=retention --retention-full=1 | cut -f1 -d"|" > results/retention-full.out

# --service=retention --retention-age
echo "--service=retention --retention-age"
$PLUGIN_PATH/check_pgbackrest --stanza=my_stanza --service=retention --retention-age=1h | cut -f1 -d"|" > results/retention-age.out

# --service=retention fail
echo "--service=retention fail"
sudo -iu postgres psql -c "SELECT pg_sleep(1);" > /dev/null 2>&1
$PLUGIN_PATH/check_pgbackrest --stanza=my_stanza --service=retention --retention-full=2 --retention-age=1s | cut -f1 -d"|" > results/retention-fail.out

## Results
diff -abB expected/ results/ > regression.diffs
if [ $(wc -l < regression.diffs) -gt 0 ]; then
     cat regression.diffs
fi
