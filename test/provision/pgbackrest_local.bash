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
log-level-console=warn
log-level-file=info

[my_stanza]
pg1-path=${PGDATA}
EOC

sudo -iu postgres pgbackrest --stanza=my_stanza stanza-create

# archive_command setup
cat <<'EOS' | "/usr/pgsql-${PGVER}/bin/psql" -U postgres
ALTER SYSTEM SET "archive_command" TO 'pgbackrest --stanza=my_stanza archive-push %p';
SELECT pg_reload_conf();
EOS

sudo -iu postgres pgbackrest --stanza=my_stanza check
sudo -iu postgres pgbackrest --stanza=my_stanza --type=full backup
sudo -iu postgres pgbackrest --stanza=my_stanza info