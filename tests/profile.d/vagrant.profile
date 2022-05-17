# Vagrant settings
export CLPATH="/home/vagrant/clusters"
# Ansible settings
export ANSIBLE_ROLES_PATH=${ANSIBLE_ROLES_PATH:+$ANSIBLE_ROLES_PATH:}$(pwd)/roles
export ANSIBLE_HOST_KEY_CHECKING=False
export ANSIBLE_REMOTE_USER="root"
export DBV=""
export EXTRA_VARS=""
