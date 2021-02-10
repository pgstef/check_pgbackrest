#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

PGVER="$1"
PGDATA="$2"
PGUSER="$3"
PGPORT="$4"
ENCRYPTED="$5"

cat<<EOC > "/etc/pgbackrest.conf"
[global]
repo1-host=backup-srv
repo1-host-user=${PGUSER}
process-max=2
log-level-console=warn
log-level-file=info
delta=y

[my_stanza]
pg1-path=${PGDATA}
pg1-user=${PGUSER}
pg1-port=${PGPORT}
EOC

# archive_command setup
cat <<'EOS' | "/usr/bin/psql" -U ${PGUSER} -d postgres
ALTER SYSTEM SET "archive_command" TO 'pgbackrest --stanza=my_stanza archive-push %p';
SELECT pg_reload_conf();
EOS