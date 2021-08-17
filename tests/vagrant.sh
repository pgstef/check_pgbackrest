#!/usr/bin/env bash
set -o errexit
set -o nounset

cd /vagrant
export RUN_ARGS=""
if [ "$ACTIVITY" == "only" ]; then
    export ACTIVITY=true
    export RUN_ARGS="-A"
fi
echo "ACTIVITY = '$ACTIVITY'"
echo "ARCH = '$ARCH'"
echo "PGBR_BUILD = '$PGBR_BUILD'"
echo "PGBR_REPO_TYPE = '$PGBR_REPO_TYPE'"
echo "PROFILE = '$PROFILE'"
source profile.d/$PROFILE.profile
source profile.d/vagrant.profile

if [ ! -z "$EXTRA" ]; then
    export EXTRA_VARS="$EXTRA_VARS $EXTRA"
fi

if $PGBR_BUILD; then
    export EXTRA_VARS="$EXTRA_VARS pgbackrest_build=true"
fi

if [ ! -z "$PGBR_REPO_TYPE" ]; then
    export EXTRA_VARS="$EXTRA_VARS pgbackrest_repo_type=$PGBR_REPO_TYPE"
    [ "$PGBR_REPO_TYPE" = "posix" ] && export EXTRA_VARS="$EXTRA_VARS pgbackrest_repo_path=/shared/repo1"
fi

[ ! -z "$edb_repository_username" ] && export EDB_REPO_USERNAME=$edb_repository_username
[ ! -z "$edb_repository_password" ] && export EDB_REPO_PASSWORD=$edb_repository_password
[ ! -z "$pgbackrest_git_url" ] && export EXTRA_VARS="$EXTRA_VARS pgbackrest_git_url=$pgbackrest_git_url"
[ ! -z "$pgbackrest_git_branch" ] && export EXTRA_VARS="$EXTRA_VARS pgbackrest_git_branch=$pgbackrest_git_branch"

echo "EXTRA_VARS = '$EXTRA_VARS'"
echo "CLNAME=$CLNAME"
sh ci.sh