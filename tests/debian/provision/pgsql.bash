#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

PGVER="$1"
PGDATA="$2"

# Common system
localedef -i en_US -f UTF-8 en_US.UTF-8
apt-get install -y gnupg2

# Create the file repository configuration:
sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'

# Import the repository signing key:
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -

# Update the package lists:
sudo apt-get update

# Install
sudo mkdir -p /etc/postgresql-common/createcluster.d
echo "initdb_options = '--data-checksums --auth-host=trust --auth-local=trust'" >> /etc/postgresql-common/createcluster.d/custom.conf
sudo apt-get -y install "postgresql-${PGVER}"
pg_lsclusters

# postgresql.conf setup
cat <<'EOS' | psql -U postgres
ALTER SYSTEM SET "listen_addresses" TO '*';
ALTER SYSTEM SET "wal_level" TO 'replica';
ALTER SYSTEM SET "archive_mode" TO 'on';
ALTER SYSTEM SET "archive_command" TO '/bin/true';
EOS
sudo pg_ctlcluster 12 main restart

# Force proper permissions on .ssh files
chmod -R 0600 /root/.ssh
chmod 0700 /root/.ssh
cp -rf /root/.ssh /var/lib/postgresql/.ssh
chown -R postgres: /var/lib/postgresql/.ssh
