#!/usr/bin/env bash

cd "$(dirname "$0")"

BRANCH="master"
if [ ! -z "$1" ]; then
    BRANCH="$1"
fi

if [ -e /usr/bin/pgbackrest ]; then
	INITIAL_VERSION=`/usr/bin/pgbackrest version | sed -e s/pgBackRest\ //`
	echo "Initial pgBackRest version is : $INITIAL_VERSION"

	if [ -f /usr/bin/pgbackrest-$INITIAL_VERSION ]; then
		rm -f  /usr/bin/pgbackrest-$INITIAL_VERSION
	fi

	mv /usr/bin/pgbackrest /usr/bin/pgbackrest-$INITIAL_VERSION
fi

yum install -y make gcc postgresql-devel openssl-devel libxml2-devel lz4-devel libzstd-devel bzip2-devel


if [ ! -d /build ]; then
	mkdir /build
else
	rm -rf /build/pgbackrest
fi

if [ "$BRANCH" == "local" ] && [ -e /pgbackrest-dev ]; then
	echo "Build local pgbackrest-dev environment"
	ln -s /pgbackrest-dev /build/pgbackrest
else
	yum install -y git
	echo "Branch to clone is : $BRANCH"
	git clone --single-branch --branch $BRANCH https://github.com/pgbackrest/pgbackrest.git /build/pgbackrest
fi

cd /build/pgbackrest/src && ./configure
make -s -C /build/pgbackrest/src
MAKE_VERSION=`/build/pgbackrest/src/pgbackrest version | sed -e s/pgBackRest\ //`
echo "pgBackRest master version is : $MAKE_VERSION"
mv /build/pgbackrest/src/pgbackrest /usr/bin/pgbackrest
