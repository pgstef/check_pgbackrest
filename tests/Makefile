### Global variables
# disable running the activity script by default
ACTIVITY='false'
# define PG on Rocky 9 as default profile
PROFILE='ro9pg'

### Make targets
init: clean_vm create_vm

uc1:
	ACTIVITY=$(ACTIVITY) ARCH='shared-storage' EXTRA="check_pgbackrest_build=true deploy_icinga2=true $(EXTRA)" PGBR_BUILD='false' PGBR_REPO_TYPE=$(PGBR_REPO_TYPE) PROFILE=$(PROFILE) vagrant up --provision-with=exec-ci
uc1_full:
	ACTIVITY=$(ACTIVITY) ARCH='shared-storage' EXTRA="check_pgbackrest_build=true deploy_icinga2=true $(EXTRA)" PGBR_BUILD='true' PGBR_REPO_TYPE=$(PGBR_REPO_TYPE) PROFILE=$(PROFILE) vagrant up --provision-with=exec-ci
uc1_light:
	ACTIVITY=$(ACTIVITY) ARCH='shared-storage' EXTRA="$(EXTRA)" PGBR_BUILD='false' PGBR_REPO_TYPE=$(PGBR_REPO_TYPE) PROFILE=$(PROFILE) vagrant up --provision-with=exec-ci

uc2:
	ACTIVITY=$(ACTIVITY) ARCH='with-repo-host' EXTRA="check_pgbackrest_build=true deploy_icinga2=true $(EXTRA)" PGBR_BUILD='false' PGBR_REPO_TYPE=$(PGBR_REPO_TYPE) PROFILE=$(PROFILE) vagrant up --provision-with=exec-ci
uc2_full:
	ACTIVITY=$(ACTIVITY) ARCH='with-repo-host' EXTRA="check_pgbackrest_build=true deploy_icinga2=true $(EXTRA)" PGBR_BUILD='true' PGBR_REPO_TYPE=$(PGBR_REPO_TYPE) PROFILE=$(PROFILE) vagrant up --provision-with=exec-ci
uc2_light:
	ACTIVITY=$(ACTIVITY) ARCH='with-repo-host' EXTRA="$(EXTRA)" PGBR_BUILD='false' PGBR_REPO_TYPE=$(PGBR_REPO_TYPE) PROFILE=$(PROFILE) vagrant up --provision-with=exec-ci

### Setup
build_all_docker_images:
	vagrant ssh -c "ansible-playbook /vagrant/platforms/docker/build_all_images.yml"

clean_ci:
	PROFILE=$(PROFILE) vagrant up --provision-with=clean-ci

clean_git:
	git clean -f -dX --dry-run

clean_icinga2:
	vagrant ssh -c "docker stop $(PROFILE)-icinga2 && docker rm $(PROFILE)-icinga2"

clean_vm:
	vagrant destroy -f

create_vm:
	vagrant up
	vagrant ssh -c "sh /vagrant/run.sh -i"
