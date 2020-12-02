#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

PGVER="$1"
PGDATA="$2"
PGUSER="$3"
PGPORT="$4"
REPO_USER="$5"
REPO_PWD="$6"

# configure EDB repo and install required packages
cat<<EOF > "/etc/yum.repos.d/edb.repo"
[edb]
name=EnterpriseDB RPMs \$releasever - \$basearch
baseurl=https://${REPO_USER}:${REPO_PWD}@yum.enterprisedb.com/edb/redhat/rhel-\$releasever-\$basearch
enabled=1
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/ENTERPRISEDB-GPG-KEY

[edb-testing]
name=EnterpriseDB Testing - Not For Production \$releasever - \$basearch
baseurl=https://${REPO_USER}:${REPO_PWD}@yum.enterprisedb.com/edb-testing/redhat/rhel-\$releasever-\$basearch
enabled=0
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/ENTERPRISEDB-GPG-KEY
EOF

curl --silent -o /etc/pki/rpm-gpg/ENTERPRISEDB-GPG-KEY https://${REPO_USER}:${REPO_PWD}@yum.enterprisedb.com/ENTERPRISEDB-GPG-KEY
rpm --import /etc/pki/rpm-gpg/ENTERPRISEDB-GPG-KEY
yum install --nogpgcheck --quiet -y -e 0 edb-as${PGVER}-server

# firewall setup
firewall-cmd --quiet --permanent --add-port=${PGPORT}/tcp
firewall-cmd --quiet --reload

# init instance
systemctl stop "edb-as-${PGVER}"
systemctl disable "edb-as-${PGVER}"
rm -rf "${PGDATA}"
export PGSETUP_INITDB_OPTIONS="-E UTF-8 --data-checksums"
"/usr/edb/as${PGVER}/bin/edb-as-${PGVER}-setup" initdb

# pg_hba setup
cat<<EOC > "${PGDATA}/pg_hba.conf"
local all         all                      trust
host  all         all      0.0.0.0/0       trust
host  all         all      ::/0            trust
local replication all                      trust
host  replication all      0.0.0.0/0       trust
host  replication all      ::/0            trust
EOC

systemctl enable "edb-as-${PGVER}"
systemctl start "edb-as-${PGVER}"

# postgresql.conf setup
cat <<'EOS' | "/usr/edb/as${PGVER}/bin/psql" -U ${PGUSER} -d postgres
ALTER SYSTEM SET "listen_addresses" TO '*';
ALTER SYSTEM SET "wal_level" TO 'replica';
ALTER SYSTEM SET "archive_mode" TO 'on';
ALTER SYSTEM SET "archive_command" TO '/bin/true';
EOS

# restart pgsql server
systemctl restart "edb-as-${PGVER}"
echo "pathmunge /usr/edb/as${PGVER}/bin" > /etc/profile.d/epas${PGVER}.sh
chmod +x /etc/profile.d/epas${PGVER}.sh

# force proper permissions on .ssh files
cp -rf /root/.ssh /var/lib/edb/.ssh
chown -R ${PGUSER}: /var/lib/edb/.ssh
restorecon -R /var/lib/edb/.ssh
usermod -aG ${PGUSER} accessed_by_ssh

# install pgBackRest
yum install --nogpgcheck --quiet -y -e 0 "https://download.postgresql.org/pub/repos/yum/reporpms/EL-7-x86_64/pgdg-redhat-repo-latest.noarch.rpm"

if ls /vagrant/rpms/pgbackrest-*.rhel7.x86_64.rpm &> /dev/null; then
	echo "-----Install the following provided rpm"
	ls /vagrant/rpms/pgbackrest-*.rhel7.x86_64.rpm
	yum install --nogpgcheck --quiet -y -e 0 /vagrant/rpms/pgbackrest-*.rhel7.x86_64.rpm
else
	yum install --nogpgcheck --quiet -y -e 0 pgbackrest
fi

chown -R ${PGUSER}: /var/lib/pgbackrest
chown -R ${PGUSER}: /var/log/pgbackrest
chown -R ${PGUSER}: /var/spool/pgbackrest