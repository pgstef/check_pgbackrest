#!/usr/bin/env bash
set -o errexit
set -o nounset
cd "$(dirname "$0")"

usage() {
    echo "Usage:"
    echo "    -c <cluster_dir>            Cluster directory."
    echo "    -C                          Cleaning step only."
    echo "    -h                          Display this help message."
    echo "    -i                          Initial step only."
}

INIT_ONLY=false
CLEAN_ONLY=false
while getopts "c:Chi" o; do
    case "${o}" in
        c)
            CLUSTER_DIR=${OPTARG}
            ;;
        C)
            CLEAN_ONLY=true
            ;;
        h )
            usage
            exit 0
            ;;
        i)
            INIT_ONLY=true
            ;;
        *)
            usage 1>&2
            exit 1
            ;;
    esac
done
shift $((OPTIND-1))

if $INIT_ONLY; then
    #-------------------------------------------------------------------------------------------------------------------
    echo '-------------------- Init --------------------' && date
    #-------------------------------------------------------------------------------------------------------------------
    # This section is intended to update the GitHub Action Runner (Ubuntu)
    echo 'Update apt'
    sudo apt-get update
    echo '--------------------'
    echo 'Whoami?'
    whoami
    echo '--------------------'
    echo 'Docker installed?'
    docker version
    echo '--------------------'
    echo 'Ansible installed?'
    ansible --version
    echo '--------------------'
    echo 'Install ansible dependencies'
    pipx inject ansible-base docker-py
    ansible-galaxy collection install community.docker
    ansible-galaxy collection install edb_devops.edb_postgres
    ansible-galaxy collection install t_systems_mms.icinga_director
    echo '--------------------'
    echo 'Install Azure Storage Blobs client library for Python'
    pip install azure-storage-blob

    # Exit with success
    exit 0;
fi

if $CLEAN_ONLY; then
    #-------------------------------------------------------------------------------------------------------------------
    echo '-------------------- Clean --------------------' && date
    #-------------------------------------------------------------------------------------------------------------------
    if [ -e $CLUSTER_DIR ]; then
        ansible-playbook platforms/deprovision.yml -e cluster_dir=$CLUSTER_DIR
        sudo rm --force --preserve-root --recursive $CLUSTER_DIR
    fi

    # Exit with success
    exit 0;
fi

#-----------------------------------------------------------------------------------------------------------------------
echo '-------------------- Provision --------------------' && date
#-----------------------------------------------------------------------------------------------------------------------
export ANSIBLE_ROLES_PATH=${ANSIBLE_ROLES_PATH:+$ANSIBLE_ROLES_PATH:}$(pwd)/roles
: "${CLUSTER_DIR:?Variable not set or empty}"
echo "CLUSTER_DIR=$CLUSTER_DIR"
ansible-playbook platforms/provision.yml -e cluster_dir=$CLUSTER_DIR
ansible-playbook platforms/system-config.yml -i "$CLUSTER_DIR/inventory.docker.yml" -e cluster_dir=$CLUSTER_DIR

#-----------------------------------------------------------------------------------------------------------------------
echo '-------------------- Deploy --------------------' && date
#-----------------------------------------------------------------------------------------------------------------------
: "${EDB_REPO_USERNAME:?Variable not set or empty}"
: "${EDB_REPO_PASSWORD:?Variable not set or empty}"
export ANSIBLE_HOST_KEY_CHECKING=False
export ANSIBLE_REMOTE_USER="root"
ansible-playbook playbooks/deploy.yml -i "$CLUSTER_DIR/inventory" -e cluster_dir=$CLUSTER_DIR

if $ACTIVITY; then
#-----------------------------------------------------------------------------------------------------------------------
echo '-------------------- Simulate basic activity --------------------' && date
#-----------------------------------------------------------------------------------------------------------------------
    ansible-playbook playbooks/activity.yml -i "$CLUSTER_DIR/inventory"
fi