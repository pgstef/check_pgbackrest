#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

PGVER="$1"
PGDATA="$2"

# install required packages
yum install --nogpgcheck --quiet -y -e 0 "https://download.postgresql.org/pub/repos/yum/reporpms/EL-7-x86_64/pgdg-redhat-repo-latest.noarch.rpm"

if [ $PGVER -ge "13" ]; then
    yum-config-manager --enable pgdg$PGVER-updates-testing
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
export PGSETUP_INITDB_OPTIONS="--data-checksums"
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
cat <<'EOS' | "/usr/pgsql-${PGVER}/bin/psql" -U postgres
ALTER SYSTEM SET "listen_addresses" TO '*';
ALTER SYSTEM SET "wal_level" TO 'replica';
ALTER SYSTEM SET "archive_mode" TO 'on';
ALTER SYSTEM SET "archive_command" TO '/bin/true';
EOS

# restart pgsql server
systemctl restart "postgresql-${PGVER}"
echo "export PATH=\$PATH:/usr/pgsql-${PGVER}/bin" >> /etc/profile

# force proper permissions on .ssh files
chmod -R 0600 /root/.ssh
chmod 0700 /root/.ssh
cp -rf /root/.ssh /var/lib/pgsql/.ssh
chown -R postgres: /var/lib/pgsql/.ssh
restorecon -R /root/.ssh
restorecon -R /var/lib/pgsql/.ssh

# create user to be accessed by ssh
adduser accessed_by_ssh
usermod -aG wheel accessed_by_ssh
usermod -aG postgres accessed_by_ssh
echo "accessed_by_ssh ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
cp -rf /root/.ssh /home/accessed_by_ssh/.ssh
chown -R accessed_by_ssh: /home/accessed_by_ssh/.ssh
restorecon -R /home/accessed_by_ssh/.ssh