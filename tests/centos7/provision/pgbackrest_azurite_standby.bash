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

CIPHER=
# pgbackrest.conf setup
if [ $ENCRYPTED = "true" ]; then
    CIPHER='repo1-cipher-type=aes-256-cbc
repo1-cipher-pass=acbd'
fi

HOST_AZURE="127.0.0.1"
HOST_AZURE_ACCOUNT="pgbackrest"
HOST_AZURE_KEY="YXpLZXk="
HOST_AZURE_CONTAINER="pgbackrest-container"

cat<<EOC > "/etc/pgbackrest.conf"
[global]
repo1-type=azure
repo1-azure-host=$HOST_AZURE
repo1-azure-verify-tls=n
repo1-azure-account=$HOST_AZURE_ACCOUNT
repo1-azure-key=$HOST_AZURE_KEY
repo1-azure-container=$HOST_AZURE_CONTAINER
repo1-path=/repo1
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