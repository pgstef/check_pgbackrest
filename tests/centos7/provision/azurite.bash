#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

# global config
CERTS_PATH="/opt/azurite/certs"
# HOST_AZURE="blob.core.windows.net"
HOST_AZURE="127.0.0.1"
HOST_AZURE_ACCOUNT="pgbackrest"
HOST_AZURE_KEY="YXpLZXk="
HOST_AZURE_CONTAINER="pgbackrest-container"

# generate certs
mkdir -p -m 755 $CERTS_PATH
cd /opt/azurite/certs
openssl genrsa -out ca.key 2048
openssl req -new -x509 -extensions v3_ca -key ca.key -out ca.crt -days 99999 -subj "/C=BE/ST=Country/L=City/O=Organization/CN=check_pgbackrest"
openssl genrsa -out server.key 2048
openssl req -new -key server.key -out server.csr -subj "/C=BE/ST=Country/L=City/O=Organization/CN=check_pgbackrest"
openssl x509 -req -in server.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out server.crt -days 99999 -sha256
cp /opt/azurite/certs/server.crt /opt/azurite/certs/public.crt
cp /opt/azurite/certs/server.key /opt/azurite/certs/private.key
chmod 644 /opt/azurite/certs/*
firewall-cmd --quiet --permanent --add-service=https
firewall-cmd --quiet --reload
# echo "127.0.0.1 $HOST_AZURE" | tee -a /etc/hosts

# run azurite
mkdir -p -m 755 /opt/azurite/data
yum install --nogpgcheck --quiet -y -e 0 docker
systemctl start docker
docker run --privileged -d -p 443:443 \
-v /opt/azurite/data:/workspace \
-v $CERTS_PATH/public.crt:/root/public.crt:ro \
-v $CERTS_PATH/private.key:/root/private.key:ro \
-e AZURITE_ACCOUNTS="$HOST_AZURE_ACCOUNT:$HOST_AZURE_KEY" \
mcr.microsoft.com/azure-storage/azurite \
azurite-blob --blobPort 443 --blobHost 0.0.0.0 --cert=/root/public.crt --key=/root/private.key -l /workspace -d /workspace/debug.log

# configure pgbackrest
cat<<EOC > /etc/pgbackrest.conf 
[global]
repo1-type=azure
repo1-azure-host=$HOST_AZURE
repo1-azure-verify-tls=n
repo1-azure-account=$HOST_AZURE_ACCOUNT
repo1-azure-key=$HOST_AZURE_KEY
repo1-azure-container=$HOST_AZURE_CONTAINER
repo1-path=/repo1
EOC

sudo -iu postgres pgbackrest repo-create

# Tips:
# Stop all running containers: docker stop $(docker ps -a -q)
# Delete all stopped containers: docker rm $(docker ps -a -q)