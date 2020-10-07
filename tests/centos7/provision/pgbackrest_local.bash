#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

PGVER="$1"
PGDATA="$2"
PGUSER="$3"
PGPORT="$4"
ENCRYPTED="$5"

PACKAGES=(
    samba
    samba-client
    cifs-utils
)

yum install --nogpgcheck --quiet -y -e 0 "${PACKAGES[@]}"

# cifs mount
groupadd --gid 2000 sambagroup
usermod -aG sambagroup ${PGUSER}

cat<<EOF >>"/etc/fstab"
//backup-srv/bckp_storage/pgbackrest /var/lib/pgbackrest cifs  username=samba_user1,password=samba,uid=${PGUSER},gid=${PGUSER},dir_mode=0750,file_mode=0740  0 0
EOF

chmod 755 /var/lib/pgbackrest
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