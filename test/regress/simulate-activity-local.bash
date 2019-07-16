#!/usr/bin/env bash
cd "$(dirname "$0")"

# vars
SCALE=10
ACTIVITY_TIME=30 #seconds

# run
echo "--Create pgbench setup"
sudo -iu postgres createdb bench
sudo -iu postgres pgbench -i -s $SCALE --quiet --foreign-keys -d bench

echo "--Take a full backup"
sudo -iu postgres pgbackrest --stanza=my_stanza --type=full backup

echo "--Simulate $ACTIVITY_TIME sec activity"
sudo -iu postgres pgbench -T $ACTIVITY_TIME -d bench

echo "--Take an incremental backup"
sudo -iu postgres pgbackrest --stanza=my_stanza --type=incr backup
sudo -iu postgres pgbackrest --stanza=my_stanza info

echo "--Simulate $ACTIVITY_TIME sec activity"
sudo -iu postgres pgbench -T $ACTIVITY_TIME -d bench

echo "--Take a full backup to test the purge action"
sudo -iu postgres pgbackrest --stanza=my_stanza --type=full backup
sudo -iu postgres pgbackrest --stanza=my_stanza info