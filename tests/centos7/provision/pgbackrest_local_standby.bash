#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

PGVER="$1"
PGDATA="$2"
PGUSER="$3"
PGPORT="$4"
PGSVC="$5"
ENCRYPTED="$6"

cat<<EOF >>"/etc/fstab"
//backup-srv/bckp_storage/pgbackrest /var/lib/pgbackrest cifs  username=samba_user1,password=samba,uid=${PGUSER},gid=${PGUSER},dir_mode=0750,file_mode=0740  0 0
EOF
mount /var/lib/pgbackrest

CIPHER=
# pgbackrest.conf setup
if [ $ENCRYPTED = "true" ]; then
    CIPHER='repo1-cipher-type=aes-256-cbc
repo1-cipher-pass=acbd'
fi

cat<<EOC > "/etc/pgbackrest.conf"
[global]
repo1-type=cifs
repo1-path=/var/lib/pgbackrest
repo1-retention-full=1
process-max=2
log-level-console=warn
log-level-file=info
start-fast=y
delta=y
backup-standby=y
$CIPHER

[my_stanza]
pg1-host=pgsql-srv
pg1-host-user=${PGUSER}
pg1-path=${PGDATA}
pg2-path=${PGDATA}
pg2-user=${PGUSER}
pg2-port=${PGPORT}
recovery-option=primary_conninfo=host=pgsql-srv user=${PGUSER} port=${PGPORT}
EOC

# build streaming replication
systemctl stop ${PGSVC}
sudo -iu ${PGUSER} pgbackrest --stanza=my_stanza --type=standby --target-timeline=latest --reset-pg1-host restore
systemctl start ${PGSVC}

# test the backup-standby option
sudo -iu ${PGUSER} pgbackrest --stanza=my_stanza --type=incr backup
sudo -iu ${PGUSER} pgbackrest --stanza=my_stanza info