#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

# global config
HOST_GCS="127.0.0.1"
HOST_GCS_BUCKET="pgbackrest"
HOST_GCS_KEY="my-token"

# firewall
firewall-cmd --quiet --permanent --add-service=https
firewall-cmd --quiet --reload

# run fake gcs server
yum install --nogpgcheck --quiet -y -e 0 docker
systemctl start docker
docker run -d -p 443:4443 fsouza/fake-gcs-server

# create pgbackrest repo
cat<<EOC > /etc/pgbackrest.conf 
[global]
repo1-type=gcs
repo1-storage-verify-tls=n
repo1-gcs-endpoint=$HOST_GCS
repo1-gcs-bucket=$HOST_GCS_BUCKET
repo1-gcs-key-type=token
repo1-gcs-key=$HOST_GCS_KEY
EOC

pgbackrest --log-level-console=info repo-create

# Tips:
# Stop all running containers: docker stop $(docker ps -a -q)
# Delete all stopped containers: docker rm $(docker ps -a -q)