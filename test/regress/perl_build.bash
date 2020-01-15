#!/usr/bin/env bash

cd "$(dirname "$0")"
PERL_VERSION="perl-5.30.1"

if [ ! -d /$PERL_VERSION ]; then
	wget https://www.cpan.org/src/5.0/$PERL_VERSION.tar.gz --directory-prefix=/tmp
	tar -xzf /tmp/$PERL_VERSION.tar.gz --directory=/tmp
	cd /tmp/$PERL_VERSION
	./Configure -des -Dprefix=/$PERL_VERSION
	make -j 4
	make -j 4 test
	make -j 4 install
	echo "export PATH=/$PERL_VERSION/bin:\$PATH" >> /etc/profile
	source /etc/profile
	export PERL_MM_USE_DEFAULT=1
	/$PERL_VERSION/bin/cpan -i "JSON"
	/$PERL_VERSION/bin/cpan -i "Net::SFTP::Foreign"
	/$PERL_VERSION/bin/cpan -i "Data::Dumper"
	/$PERL_VERSION/bin/cpan -i "Config::IniFiles"

	# /$PERL_VERSION/bin/cpan -i "Time::Zone"
	# /$PERL_VERSION/bin/cpan -i "DateTime::Format::HTTP"
	# /$PERL_VERSION/bin/cpan -i "Digest::MD5::File"
	# /$PERL_VERSION/bin/cpan -i "HTTP::Date"
	# /$PERL_VERSION/bin/cpan -i "HTTP::Response"
	# /$PERL_VERSION/bin/cpan -i "HTTP::Status"
	# /$PERL_VERSION/bin/cpan -i "LWP"
	# /$PERL_VERSION/bin/cpan -i "LWP::Simple"
	# /$PERL_VERSION/bin/cpan -i "LWP::UserAgent::Determined"
	# /$PERL_VERSION/bin/cpan -i "MooseX::Types::DateTime::MoreCoercions"
	# /$PERL_VERSION/bin/cpan -i "Test::LoadAllModules"

	# /$PERL_VERSION/bin/cpan -i "Net::Amazon::S3"
else
	echo "$PERL_VERSION already installed"
fi