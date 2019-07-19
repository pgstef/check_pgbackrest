#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

# create an HTTP setup
cat<<EOF >"/opt/minio/minio-http.conf"
MINIO_VOLUMES=/opt/minio/data
MINIO_DOMAIN=minio.local
MINIO_OPTS="--address :80 --compat"
MINIO_ACCESS_KEY="accessKey"
MINIO_SECRET_KEY="superSECRETkey" 
EOF

chown minio:minio "/opt/minio/minio-http.conf"

# systemd service
cat<<EOF >"/etc/systemd/system/minio-http.service"
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

EnvironmentFile=-/opt/minio/minio-http.conf
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

firewall-cmd --permanent --add-service=http
firewall-cmd --quiet --reload
systemctl enable minio-http
systemctl start minio-http
sudo -iu postgres psql -c "SELECT pg_sleep(5);" > /dev/null 2>&1
systemctl status minio-http