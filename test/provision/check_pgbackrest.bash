#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

# build rpm and install check_pgbackrest
yum install --nogpgcheck --quiet -y -e 0 epel-release
yum groups mark install "Development Tools"
yum groups mark convert "Development Tools"
yum groupinstall --nogpgcheck --quiet -y -e 0 "Development Tools"
yum install --nogpgcheck --quiet -y -e 0 rpmdevtools
rpmdev-setuptree
spectool -R -g /check_pgbackrest/check_pgbackrest.spec
rpmbuild -ba /check_pgbackrest/check_pgbackrest.spec
ls -lr ~/rpmbuild/RPMS/noarch/*
yum install --nogpgcheck --quiet -y -e 0 ~/rpmbuild/RPMS/noarch/*.rpm