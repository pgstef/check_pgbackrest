#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail


PACKAGES=(
    samba
    samba-client
    policycoreutils-python
)

yum install --nogpgcheck --quiet -y -e 0 "${PACKAGES[@]}"
setsebool -P samba_export_all_ro on
setsebool -P samba_export_all_rw on
setsebool -P samba_share_nfs on

mkdir -p /samba/export_rw/pgbackrest
useradd samba_user1
chown -R samba_user1:samba_user1 /samba/export_rw
semanage fcontext -at samba_share_t "/samba/export_rw(/.*)?"
restorecon -R /samba/export_rw

firewall-cmd --permanent --add-service=samba
systemctl restart firewalld

cat<<EOF >> "/etc/samba/smb.conf"
[bckp_storage]
  comment = Folder for storing backups
  read only = no
  available = yes
  path = /samba/export_rw
  public = yes
  valid users = samba_user1
  write list = samba_user1
  writable = yes
  browseable = yes
EOF

echo 'samba' | tee - | smbpasswd -s -a samba_user1

systemctl enable smb
systemctl start smb