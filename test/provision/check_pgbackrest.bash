#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

yum install --nogpgcheck --quiet -y -e 0 epel-release

PACKAGES=(
    nagios-plugins perl-JSON perl-Net-SFTP-Foreign
)

yum install --nogpgcheck --quiet -y -e 0 "${PACKAGES[@]}"

cp /check_pgbackrest/check_pgbackrest /usr/lib64/nagios/plugins/check_pgbackrest