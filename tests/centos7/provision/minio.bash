#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

# install MinIO
# based on https://www.centosblog.com/install-configure-minio-object-storage-server-centos-linux/
useradd -s /sbin/nologin -d /opt/minio minio
mkdir -p /opt/minio/bin
mkdir /opt/minio/data

# download ~40MB, this step will take some time...
echo "--wget minio: download ~40MB, this step will take some time..."
wget --quiet https://dl.min.io/server/minio/release/linux-amd64/minio -O /opt/minio/bin/minio
chmod +x /opt/minio/bin/minio

# generate self-signed certificates
mkdir -p -m 755 /opt/minio/certs
cd /opt/minio/certs
openssl genrsa -out ca.key 2048
openssl req -new -x509 -extensions v3_ca -key ca.key -out ca.crt -days 99999 -subj "/C=BE/ST=Country/L=City/O=Organization/CN=check_pgbackrest"
openssl genrsa -out server.key 2048
openssl req -new -key server.key -out server.csr -subj "/C=BE/ST=Country/L=City/O=Organization/CN=check_pgbackrest"
openssl x509 -req -in server.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out server.crt -days 99999 -sha256
cp /opt/minio/certs/server.crt /opt/minio/certs/public.crt
cp /opt/minio/certs/server.key /opt/minio/certs/private.key
chmod 644 /opt/minio/certs/*

# basic configuration
cat<<EOF >"/opt/minio/minio.conf"
MINIO_VOLUMES=/opt/minio/data
MINIO_DOMAIN=minio.local
MINIO_OPTS="--certs-dir /opt/minio/certs --address :443 --compat"
MINIO_ACCESS_KEY="accessKey"
MINIO_SECRET_KEY="superSECRETkey" 
EOF

cat<<EOF >>"/etc/hosts"
127.0.0.1 pgbackrest.minio.local minio.local s3.eu-west-3.amazonaws.com
EOF

chown -R minio:minio /opt/minio

# systemd service
cat<<EOF >"/etc/systemd/system/minio.service"
[Unit]
Description=Minio
Documentation=https://docs.minio.io
Wants=network-online.target
After=network-online.target
AssertFileIsExecutable=/opt/minio/bin/minio

[Service]
AmbientCapabilities=CAP_NET_BIND_SERVICE
WorkingDirectory=/opt/minio

User=minio
Group=minio

PermissionsStartOnly=true

EnvironmentFile=-/opt/minio/minio.conf
ExecStartPre=/bin/bash -c "[ -n \\"\${MINIO_VOLUMES}\\" ] || echo \\"Variable MINIO_VOLUMES not set in /opt/minio/minio.conf\\""

ExecStart=/opt/minio/bin/minio server \$MINIO_OPTS \$MINIO_VOLUMES

StandardOutput=journal
StandardError=inherit

# Specifies the maximum file descriptor number that can be opened by this process
LimitNOFILE=65536

# Disable timeout logic and wait until process is stopped
TimeoutStopSec=0

# SIGTERM signal is used to stop Minio
KillSignal=SIGTERM

SendSIGKILL=no

SuccessExitStatus=0

[Install]
WantedBy=multi-user.target
EOF

firewall-cmd --quiet --permanent --add-service=https
firewall-cmd --quiet --reload
systemctl enable minio
systemctl start minio
sleep 5
systemctl restart minio
sleep 5
systemctl status minio

# install s3cmd
yum --enablerepo epel-testing install --nogpgcheck --quiet -y -e 0 s3cmd

cat<<EOF > ~/.s3cfg
host_base = minio.local
host_bucket = pgbackrest.minio.local
bucket_location = eu-west-3
use_https = true
access_key = accessKey
secret_key = superSECRETkey
EOF

# create "pgbackrest" bucket and sub-directory "repo1"
s3cmd mb --no-check-certificate s3://pgbackrest
mkdir /opt/minio/data/pgbackrest/repo1
chown minio: /opt/minio/data/pgbackrest/repo1
s3cmd ls --no-check-certificate s3://pgbackrest/repo1