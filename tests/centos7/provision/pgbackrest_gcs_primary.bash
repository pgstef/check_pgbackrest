#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

PGVER="$1"
PGDATA="$2"
PGUSER="$3"
PGPORT="$4"
ENCRYPTED="$5"

CIPHER=
# pgbackrest.conf setup
if [ $ENCRYPTED = "true" ]; then
    CIPHER='repo1-cipher-type=aes-256-cbc
repo1-cipher-pass=acbd'
fi

HOST_GCS="backup-srv"
HOST_GCS_BUCKET="pgbackrest"
HOST_GCS_KEY="my-token"

cat<<EOC > "/etc/pgbackrest.conf"
[global]
repo1-type=gcs
repo1-storage-verify-tls=n
repo1-gcs-endpoint=$HOST_GCS
repo1-gcs-bucket=$HOST_GCS_BUCKET
repo1-gcs-key-type=token
repo1-gcs-key=$HOST_GCS_KEY
repo1-path=/repo1
repo1-retention-full=1
process-max=2
log-level-console=warn
log-level-file=info
start-fast=y
delta=y
$CIPHER

[my_stanza]
pg1-path=${PGDATA}
pg1-user=${PGUSER}
pg1-port=${PGPORT}
EOC

sudo -iu ${PGUSER} pgbackrest --stanza=my_stanza stanza-create

# archive_command setup
cat <<'EOS' | "/usr/bin/psql" -U ${PGUSER} -d postgres
ALTER SYSTEM SET "archive_command" TO 'pgbackrest --stanza=my_stanza archive-push %p';
SELECT pg_reload_conf();
EOS

sudo -iu ${PGUSER} pgbackrest --stanza=my_stanza check
sudo -iu ${PGUSER} pgbackrest --stanza=my_stanza backup --type=full --repo1-retention-full=1
sudo -iu ${PGUSER} pgbackrest --stanza=my_stanza info