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
repo1-host=backup-srv
repo1-host-user=postgres
process-max=2
log-level-console=warn
log-level-file=info
delta=y

[my_stanza]
pg1-path=${PGDATA}
EOC

# archive_command setup
cat <<'EOS' | "/usr/pgsql-${PGVER}/bin/psql" -U postgres
ALTER SYSTEM SET "archive_command" TO 'pgbackrest --stanza=my_stanza archive-push %p';
SELECT pg_reload_conf();
EOS
