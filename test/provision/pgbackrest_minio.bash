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

[my_stanza]
pg1-path=${PGDATA}
EOC

# setup DNS alias for backup-srv where minio is installed
MINIO_IP=`getent hosts backup-srv | awk '{ print $1 }'`
cat<<EOF >>"/etc/hosts"
$MINIO_IP pgbackrest.minio.local minio.local s3.eu-west-3.amazonaws.com
EOF

# archive_command setup
sudo -iu postgres pgbackrest --stanza=my_stanza stanza-create

cat <<'EOS' | "/usr/pgsql-${PGVER}/bin/psql" -U postgres
ALTER SYSTEM SET "archive_command" TO 'pgbackrest --stanza=my_stanza archive-push %p';
SELECT pg_reload_conf();
EOS

sudo -iu postgres pgbackrest --stanza=my_stanza check

# install perl modules needed for check_pgbackrest S3 compatibility
yum install --nogpgcheck --quiet -y -e 0 http://repo.openfusion.net/centos7-x86_64/openfusion-release-0.7-1.of.el7.noarch.rpm
yum install  --nogpgcheck --quiet -y -e 0 perl-Config-IniFiles perl-Net-Amazon-S3