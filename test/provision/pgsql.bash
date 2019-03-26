#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

PGVER="$1"
PGDATA="$2"

# assign a host name
sed -i 's/^127\.0\.0\.1\t.*/127\.0\.0\.1\tlocalhost pgsql-srv/' /etc/hosts
hostnamectl set-hostname "pgsql-srv"

# install required packages
P=$(curl -s "https://download.postgresql.org/pub/repos/yum/${PGVER}/redhat/rhel-7-x86_64/"|grep -Eo "pgdg-centos[0-9.]+-${PGVER}-[0-9]+\.noarch.rpm"|head -1)

if ! rpm --quiet -q "${P/.rpm}"; then
    yum install --nogpgcheck --quiet -y -e 0 "https://download.postgresql.org/pub/repos/yum/${PGVER}/redhat/rhel-7-x86_64/$P"
fi

PACKAGES=(
    "postgresql${PGVER}"
    "postgresql${PGVER}-server"
    "postgresql${PGVER}-contrib"
)

yum install --nogpgcheck --quiet -y -e 0 "${PACKAGES[@]}"

# firewall setup
systemctl enable firewalld
systemctl start  firewalld
firewall-cmd --quiet --permanent --add-service=postgresql
firewall-cmd --quiet --reload

# init instance
systemctl stop "postgresql-${PGVER}"
systemctl disable "postgresql-${PGVER}"
rm -rf "${PGDATA}"
"/usr/pgsql-${PGVER}/bin/postgresql-${PGVER}-setup" initdb

# pg_hba setup
cat<<EOC > "${PGDATA}/pg_hba.conf"
local all         all                      trust
host  all         all      0.0.0.0/0       trust
EOC

systemctl start "postgresql-${PGVER}"

# postgresql.conf setup
cat <<'EOS' | "/usr/pgsql-${PGVER}/bin/psql" -U postgres
ALTER SYSTEM SET "listen_addresses" TO '*';
ALTER SYSTEM SET "wal_level" TO 'replica';
ALTER SYSTEM SET "archive_mode" TO 'on';
ALTER SYSTEM SET "archive_command" TO '/bin/true';
EOS

# restart master pgsql
systemctl restart "postgresql-${PGVER}"