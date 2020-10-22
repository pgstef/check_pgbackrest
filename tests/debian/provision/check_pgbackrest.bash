#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

# check-pgbackrest from PGDG repo
PLUGIN_PATH=/usr/bin/
sudo apt-get -y install check-pgbackrest

# Initiate backups (full, diff, incr)
echo "Initiate backups (full, diff, incr)"
sudo -iu postgres pgbackrest --stanza=my_stanza backup --type=full --repo1-retention-full=1
sudo -iu postgres pgbackrest --stanza=my_stanza backup --type=diff
sudo -iu postgres pgbackrest --stanza=my_stanza backup --type=incr
sudo -iu postgres pgbackrest --stanza=my_stanza info

echo "--list"
$PLUGIN_PATH/check_pgbackrest --list
echo "--version"
$PLUGIN_PATH/check_pgbackrest --version

echo "--service=retention --retention-full"
$PLUGIN_PATH/check_pgbackrest --stanza=my_stanza --service=retention --retention-full=1
printf "\n"
echo "--service=retention --retention-age"
$PLUGIN_PATH/check_pgbackrest --stanza=my_stanza --service=retention --retention-age=1h
printf "\n"
echo "--service=retention --retention-age-to-full"
$PLUGIN_PATH/check_pgbackrest --stanza=my_stanza --service=retention --retention-age-to-full=1h
printf "\n"

echo "--service=archives --repo-path"
$PLUGIN_PATH/check_pgbackrest --stanza=my_stanza --service=archives --repo-path=/var/lib/pgbackrest/archive
printf "\n"
echo "--service=archives --repo-path --enable-internal-pgbr-cmds --output=human --debug"
$PLUGIN_PATH/check_pgbackrest --stanza=my_stanza --service=archives --repo-path=/var/lib/pgbackrest/archive --enable-internal-pgbr-cmds --output=human --debug
