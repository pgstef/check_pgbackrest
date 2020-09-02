#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

PGVER="$1"
PGDATA="$2"

# Install pgbackrest
sudo apt-get -y install pgbackrest

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
pg1-path=${PGDATA}
EOC

sudo -iu postgres pgbackrest --stanza=my_stanza stanza-create

# archive_command setup
cat <<'EOS' | psql -U postgres
ALTER SYSTEM SET "archive_command" TO 'pgbackrest --stanza=my_stanza archive-push %p';
SELECT pg_reload_conf();
EOS

sudo -iu postgres pgbackrest --stanza=my_stanza check
