#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

PLUGIN_PATH=/usr/lib64/nagios/plugins

yum install --nogpgcheck --quiet -y -e 0 epel-release

PACKAGES=(
    nagios-plugins
    nagios-plugins-all
    perl-JSON
    perl-Net-SFTP-Foreign
    perl-Data-Dumper
    wget
    perl-Devel-NYTProf
    perl-JSON-MaybeXS
)

yum install --nogpgcheck --quiet -y -e 0 "${PACKAGES[@]}"
cp /check_pgbackrest/check_pgbackrest $PLUGIN_PATH
chmod 755 $PLUGIN_PATH/check_pgbackrest
echo "export PATH=\$PATH:/usr/lib64/nagios/plugins" >> /etc/profile

# set timezone
ln -sf /usr/share/zoneinfo/Europe/Brussels /etc/localtime

# firewall setup
systemctl enable firewalld
systemctl start  firewalld

# force proper permissions on .ssh files
chmod -R 0600 /root/.ssh
chmod 0700 /root/.ssh
restorecon -R /root/.ssh

# create user to be accessed by ssh
adduser accessed_by_ssh
usermod -aG wheel accessed_by_ssh
echo "accessed_by_ssh ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
cp -rf /root/.ssh /home/accessed_by_ssh/.ssh
chown -R accessed_by_ssh: /home/accessed_by_ssh/.ssh
restorecon -R /home/accessed_by_ssh/.ssh