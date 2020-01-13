#!/usr/bin/env bash

cd "$(dirname "$0")"

if [ -e /usr/bin/pgbackrest ]; then
	INITIAL_VERSION=`/usr/bin/pgbackrest version | sed -e s/pgBackRest\ //`
	echo "Initial pgBackRest version is : $INITIAL_VERSION"

	if [ -f /usr/bin/pgbackrest-$INITIAL_VERSION ]; then
		rm -f  /usr/bin/pgbackrest-$INITIAL_VERSION
	fi

	mv /usr/bin/pgbackrest /usr/bin/pgbackrest-$INITIAL_VERSION
fi

yum install -y gcc make openssl-devel libxml2-devel postgresql-devel perl-ExtUtils-Embed

if [ ! -d /build ]; then
	mkdir /build
else
	rm -rf /build
fi

yum install -y git
git clone https://github.com/pgbackrest/pgbackrest.git /build/pgbackrest
cd /build/pgbackrest/src && ./configure
make -s -C /build/pgbackrest/src

MAKE_VERSION=`/build/pgbackrest/src/pgbackrest version | sed -e s/pgBackRest\ //`
echo "pgBackRest master version is : $MAKE_VERSION"
mv /build/pgbackrest/src/pgbackrest /usr/bin/pgbackrest
