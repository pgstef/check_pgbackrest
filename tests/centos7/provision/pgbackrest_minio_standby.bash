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
repo1-path=/repo1
repo1-type=s3
repo1-s3-endpoint=minio.local
repo1-s3-bucket=pgbackrest
repo1-s3-verify-tls=n
repo1-s3-key=accessKey
repo1-s3-key-secret=superSECRETkey
repo1-s3-region=eu-west-3
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