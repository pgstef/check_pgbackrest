#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

PGVER="$1"
PGDATA="$2"

PACKAGES=(
    pgbackrest
    samba
    samba-client
    cifs-utils
)

yum install --nogpgcheck --quiet -y -e 0 "${PACKAGES[@]}"

# cifs mount
mkdir -p /mnt/backups
groupadd --gid 2000 sambagroup
usermod -aG sambagroup postgres

cat<<EOF >>"/etc/fstab"
//backup-srv/bckp_storage/pgbackrest /var/lib/pgbackrest cifs  username=samba_user1,password=samba,uid=postgres,gid=postgres,dir_mode=0750,file_mode=0740  0 0
EOF

chmod 755 /var/lib/pgbackrest
mount /var/lib/pgbackrest

# pgbackrest.conf setup
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
repo1-cipher-type=aes-256-cbc
repo1-cipher-pass=acbd

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


 

