#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

PGVER="$1"
PGDATA="$2"
PGUSER="$3"

# install required packages
yum install --nogpgcheck --quiet -y -e 0 "https://download.postgresql.org/pub/repos/yum/reporpms/EL-7-x86_64/pgdg-redhat-repo-latest.noarch.rpm"

if [ $PGVER -ge "14" ]; then
    yum-config-manager --enable pgdg$PGVER-updates-testing
fi

PACKAGES=(
    "postgresql${PGVER}"
    "postgresql${PGVER}-server"
    "postgresql${PGVER}-contrib"
)

yum install --nogpgcheck --quiet -y -e 0 "${PACKAGES[@]}"

# install pgBackRest
yum install --nogpgcheck --quiet -y -e 0 pgbackrest

# firewall setup
firewall-cmd --quiet --permanent --add-service=postgresql
firewall-cmd --quiet --reload

# init instance
systemctl stop "postgresql-${PGVER}"
systemctl disable "postgresql-${PGVER}"
rm -rf "${PGDATA}"
export PGSETUP_INITDB_OPTIONS="-E UTF-8 --data-checksums"
"/usr/pgsql-${PGVER}/bin/postgresql-${PGVER}-setup" initdb

# pg_hba setup
cat<<EOC > "${PGDATA}/pg_hba.conf"
local all         all                      trust
host  all         all      0.0.0.0/0       trust
host  all         all      ::/0            trust
host  replication all      0.0.0.0/0       trust
host  replication all      ::/0            trust
EOC

systemctl enable "postgresql-${PGVER}"
systemctl start "postgresql-${PGVER}"

# postgresql.conf setup
cat <<'EOS' | "/usr/pgsql-${PGVER}/bin/psql" -U ${PGUSER}
ALTER SYSTEM SET "listen_addresses" TO '*';
ALTER SYSTEM SET "wal_level" TO 'replica';
ALTER SYSTEM SET "archive_mode" TO 'on';
ALTER SYSTEM SET "archive_command" TO '/bin/true';
EOS

# restart pgsql server
systemctl restart "postgresql-${PGVER}"
echo "pathmunge /usr/pgsql-${PGVER}/bin" > /etc/profile.d/pgsql${PGVER}.sh
chmod +x /etc/profile.d/pgsql${PGVER}.sh

# force proper permissions on .ssh files
cp -rf /root/.ssh /var/lib/pgsql/.ssh
chown -R ${PGUSER}: /var/lib/pgsql/.ssh
restorecon -R /var/lib/pgsql/.ssh
usermod -aG ${PGUSER} accessed_by_ssh