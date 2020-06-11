#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

PGVER="$1"
PGDATA="$2"

PACKAGES=(
    pgbackrest
)

yum install --nogpgcheck --quiet -y -e 0 "${PACKAGES[@]}"

# pgbackrest.conf setup
cat<<EOC > "/etc/pgbackrest.conf"
[global]
repo1-path=/var/lib/pgbackrest
repo1-retention-full=1
process-max=2
log-level-console=warn
log-level-file=info
start-fast=y
delta=y
repo1-cipher-type=aes-256-cbc
repo1-cipher-pass=acbd

[my_stanza]
pg1-host=pgsql-srv
pg1-path=${PGDATA}
EOC

sudo -iu postgres pgbackrest --stanza=my_stanza stanza-create
sudo -iu postgres pgbackrest --stanza=my_stanza check
sudo -iu postgres pgbackrest --stanza=my_stanza backup --type=full --repo1-retention-full=1

# force proper permissions on repo1-path
chmod 755 /var/lib/pgbackrest

# create a specific setup to use pgBackRest restore to build streaming replication
cat<<EOC > "/etc/pgbackrest-restore.conf"
[global]
repo1-path=/var/lib/pgbackrest
process-max=2
log-level-console=warn
log-level-file=info
delta=y
repo1-cipher-type=aes-256-cbc
repo1-cipher-pass=acbd

[my_stanza]
pg1-path=${PGDATA}
recovery-option=primary_conninfo=host=pgsql-srv
recovery-option=recovery_target_timeline=latest
EOC

systemctl stop "postgresql-${PGVER}"
sudo -iu postgres pgbackrest --stanza=my_stanza --config=/etc/pgbackrest-restore.conf --type=standby restore
systemctl start "postgresql-${PGVER}"