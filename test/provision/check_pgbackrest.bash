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
)

yum install --nogpgcheck --quiet -y -e 0 "${PACKAGES[@]}"
cp /check_pgbackrest/check_pgbackrest $PLUGIN_PATH
chmod 755 $PLUGIN_PATH/check_pgbackrest
echo "export PATH=\$PATH:/usr/lib64/nagios/plugins" >> /etc/profile