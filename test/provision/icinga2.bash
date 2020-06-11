#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

yum install --nogpgcheck --quiet -y -e 0 https://packages.icinga.com/epel/icinga-rpm-release-7-latest.noarch.rpm

PACKAGES=(
    icinga2
    icinga2-selinux
    icinga2-ido-pgsql
)

yum install --nogpgcheck --quiet -y -e 0 "${PACKAGES[@]}"

systemctl enable icinga2
systemctl start icinga2

# link icinga2 - postgresql
sudo -iu postgres psql -c "CREATE ROLE icinga WITH LOGIN;"
sudo -iu postgres createdb -O icinga -E UTF8 icinga
psql -U icinga -d icinga -c "select version();"
psql -U icinga -d icinga < /usr/share/icinga2-ido-pgsql/schema/pgsql.sql
icinga2 feature enable ido-pgsql
icinga2 feature enable debuglog

# setup api for icingaweb2
icinga2 api setup
cat <<EOF >>/etc/icinga2/conf.d/api-users.conf
object ApiUser "icingaweb2" {
  password = "Wijsn8Z9eRs5E25d"
  permissions = [ "*" ]
}
EOF
systemctl restart icinga2

# setup httpd for icingaweb2
yum install --nogpgcheck --quiet -y -e 0 httpd
systemctl enable httpd
systemctl start httpd
firewall-cmd --add-service=http
firewall-cmd --permanent --add-service=http
touch /var/www/html/index.html
chmod 755 /var/www/html/index.html

# install icingaweb2
yum install --nogpgcheck --quiet -y -e 0 centos-release-scl
yum install --nogpgcheck --quiet -y -e 0 icingaweb2 icingacli icingaweb2-selinux php-pecl-imagick
echo "date.timezone = Europe/Brussels">> /etc/opt/rh/rh-php73/php.ini
systemctl start rh-php73-php-fpm.service
systemctl enable rh-php73-php-fpm.service
sudo -iu postgres psql -c "CREATE ROLE icingaweb WITH LOGIN;"
sudo -iu postgres createdb -O icingaweb -E UTF8 icingaweb
psql -U icingaweb -d icingaweb < /usr/share/doc/icingaweb2/schema/pgsql.schema.sql
systemctl restart httpd

# configure icingaweb2
cat <<EOF >>/etc/icingaweb2/authentication.ini 
[icingaweb2]
backend = "db"
resource = "icingaweb_db"
EOF

cat <<EOF >>/etc/icingaweb2/config.ini 
[global]
show_stacktraces = "1"
show_application_state_messages = "1"
config_backend = "db"
config_resource = "icingaweb_db"

[logging]
log = "syslog"
level = "ERROR"
application = "icingaweb2"
facility = "user"
EOF

cat <<EOF >>/etc/icingaweb2/groups.ini 
[icingaweb2]
backend = "db"
resource = "icingaweb_db"
EOF

cat <<EOF >>/etc/icingaweb2/resources.ini 
[icingaweb_db]
type = "db"
db = "pgsql"
host = "/var/run/postgresql"
port = "5432"
dbname = "icingaweb"
username = "icingaweb"
password = "icingaweb"
charset = ""
use_ssl = "0"

[icinga_ido]
type = "db"
db = "pgsql"
host = "/var/run/postgresql"
port = "5432"
dbname = "icinga"
username = "icinga"
password = "icinga"
charset = ""
use_ssl = "0"
EOF

cat <<EOF >>/etc/icingaweb2/roles.ini 
[Administrators]
users = "icingaweb"
permissions = "*"
groups = "Administrators"
EOF

if [ ! -d /etc/icingaweb2/modules/monitoring ]; then
	mkdir /etc/icingaweb2/modules/monitoring
fi

cat <<EOF >>/etc/icingaweb2/modules/monitoring/config.ini 
[security]
protected_customvars = "*pw*,*pass*,community"
EOF

cat <<EOF >>/etc/icingaweb2/modules/monitoring/backends.ini
[icinga]
type = "ido"
resource = "icinga_ido"
EOF

cat <<EOF >>/etc/icingaweb2/modules/monitoring/commandtransports.ini
[icinga2]
transport = "api"
host = "localhost"
port = "5665"
username = "icingaweb2"
password = "Wijsn8Z9eRs5E25d"
EOF

chown -R apache:icingaweb2 /etc/icingaweb2
icingacli module enable monitoring
psql -U icingaweb -d icingaweb -c "INSERT INTO public.icingaweb_group (name, ctime) VALUES ('Administrators', now());"
psql -U icingaweb -d icingaweb -c $'INSERT INTO icingaweb_user (name, active, password_hash) VALUES (\'icingaweb\', 1, \'$2y$10$lZil3NzXm.XC55NB4fxb8e4oMIJKh8Awa6BSjf9ka2bH4yCHgukTu\');'

# add pgsql-srv host
cat <<EOF >>/etc/icinga2/conf.d/hosts.conf

object Host "pgsql-srv" {
  import "generic-host"
  address = "pgsql-srv"
  vars.os= "Linux"
}

object Host "backup-srv" {
  import "generic-host"
  address = "backup-srv"
  vars.os= "Linux"
}
EOF

systemctl restart icinga2

# ssh configuration
cp -rf /root/.ssh /var/spool/icinga2/.ssh
chown -R icinga: /var/spool/icinga2/.ssh
restorecon -R /var/spool/icinga2/.ssh

# show
icingacli monitoring list services