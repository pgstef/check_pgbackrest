### Global variables
# disable running the activity script by default
ACTIVITY='false'
# define PG on CentOS 7 as default profile
PROFILE='c7pg'

### Make targets
init: clean_vm create_vm

uc1:
	ACTIVITY=$(ACTIVITY) ARCH='use-case-1' PGBR_BUILD='false' PGBR_REPO_TYPE=$(PGBR_REPO_TYPE) PROFILE=$(PROFILE) vagrant up --provision-with=exec-ci
uc1_full:
	ACTIVITY=$(ACTIVITY) ARCH='use-case-1' PGBR_BUILD='true' PGBR_REPO_TYPE=$(PGBR_REPO_TYPE) PROFILE=$(PROFILE) vagrant up --provision-with=exec-ci

uc2:
	ACTIVITY=$(ACTIVITY) ARCH='use-case-2' PGBR_BUILD='false' PGBR_REPO_TYPE=$(PGBR_REPO_TYPE) PROFILE=$(PROFILE) vagrant up --provision-with=exec-ci
uc2_full:
	ACTIVITY=$(ACTIVITY) ARCH='use-case-2' PGBR_BUILD='true' PGBR_REPO_TYPE=$(PGBR_REPO_TYPE) PROFILE=$(PROFILE) vagrant up --provision-with=exec-ci

### Setup
clean_ci:
	PROFILE=$(PROFILE) vagrant up --provision-with=clean-ci

clean_docker:
	vagrant ssh -c "docker rm -f $(docker ps -a -q)"

clean_git:
	git clean -f -dX --dry-run

clean_vm:
	vagrant destroy -f

create_vm:
	vagrant up
	vagrant ssh -c "sh /vagrant/run.sh -i"