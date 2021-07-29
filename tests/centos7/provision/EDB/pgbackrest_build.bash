#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

PGVER="$1"
PGBR_BRANCH="$2"
EDB_PATH="/usr/edb/as${PGVER}"

if [[ -e "/usr/bin/pgbackrest" && ! -L "/usr/bin/pgbackrest" ]]; then
	mv /usr/bin/pgbackrest /usr/bin/pgbackrest.origin
	ORIG_VERSION=`/usr/bin/pgbackrest.origin version | sed -e s/pgBackRest\ //`
	alternatives --install /usr/bin/pgbackrest pgbackrest /usr/bin/pgbackrest.origin `echo $ORIG_VERSION | tr -d . | tr -d dev`
fi

if [ -e $EDB_PATH/bin/pgbackrest ]; then
	rm -f  $EDB_PATH/bin/pgbackrest
fi

yum install --nogpgcheck --quiet -y -e 0 make gcc openssl-devel libxml2-devel lz4-devel libzstd-devel bzip2-devel libyaml-devel

if [ ! -d /build ]; then
	mkdir /build
else
	rm -rf /build/pgbackrest
fi

if [ "$PGBR_BRANCH" == "local" ] && [ -e /pgbackrest ]; then
	echo "Build local pgbackrest environment"
	ln -s /pgbackrest /build/pgbackrest
else
	yum install --nogpgcheck --quiet -y -e 0 git
	echo "Branch to clone is : $PGBR_BRANCH"
	git clone --single-branch --branch $PGBR_BRANCH https://github.com/pgbackrest/pgbackrest.git /build/pgbackrest
fi

export CPPFLAGS="-I $EDB_PATH/include"
export PATH=$EDB_PATH/bin/:$PATH
export LDFLAGS="-L$EDB_PATH/lib"
cd /build/pgbackrest/src && ./configure
make -s -C /build/pgbackrest/src
MAKE_VERSION=`/build/pgbackrest/src/pgbackrest version | sed -e s/pgBackRest\ //`
echo "pgBackRest $PGBR_BRANCH version is : $MAKE_VERSION"
mv /build/pgbackrest/src/pgbackrest $EDB_PATH/bin/pgbackrest
alternatives --install /usr/bin/pgbackrest pgbackrest $EDB_PATH/bin/pgbackrest `echo $MAKE_VERSION | tr -d . | tr -d dev`