### Global variables
EPAS='false'

### Make scenario
s1: clean create_vm cifs pgbackrest_local icinga2_local generate_config_file_local
s1_full: clean create_vm cifs pgbackrest_build pgbackrest_local icinga2_local generate_config_file_local
s1_light: clean create_vm cifs pgbackrest_local generate_config_file_local

s2: clean create_vm pgbackrest_remote icinga2_remote generate_config_file_remote
s2_full: clean create_vm pgbackrest_build pgbackrest_remote icinga2_remote generate_config_file_remote
s2_light: clean create_vm pgbackrest_remote generate_config_file_remote

s3: clean create_vm pgbackrest_minio icinga2_minio generate_config_file_local
s3_full: clean create_vm pgbackrest_build pgbackrest_minio icinga2_minio generate_config_file_local
s3_light: clean create_vm pgbackrest_minio generate_config_file_local

### Setup
clean:
	vagrant destroy -f

clean_git:
	git clean -f -dX --dry-run

create_vm:
	EPAS=$(EPAS) vagrant up

### Configuration
cifs:
	vagrant up --provision-with=cifs

pgbackrest_local:
	EPAS=$(EPAS) vagrant up --provision-with=pgbackrest_local

pgbackrest_remote:
	EPAS=$(EPAS) vagrant up --provision-with=pgbackrest_remote_primary
	EPAS=$(EPAS) vagrant up --provision-with=pgbackrest_remote_standby

pgbackrest_minio:
	vagrant up --provision-with=minio
	vagrant up --provision-with=minio_http
	EPAS=$(EPAS) vagrant up --provision-with=pgbackrest_minio

icinga2_local:
	EPAS=false vagrant up --provision-with=icinga2 # use PostgreSQL to install icinga2
	EPAS=$(EPAS) vagrant up --provision-with=icinga2_local

icinga2_remote:
	EPAS=false vagrant up --provision-with=icinga2 # use PostgreSQL to install icinga2
	EPAS=$(EPAS) vagrant up --provision-with=icinga2_remote

icinga2_minio:
	EPAS=false vagrant up --provision-with=icinga2 # use PostgreSQL to install icinga2
	EPAS=$(EPAS) vagrant up --provision-with=icinga2_minio

### Specific operations
pgbackrest_build:
	EPAS=$(EPAS) vagrant up --provision-with=pgbackrest_build

perl_build:
	vagrant up --provision-with=perl_build

generate_config_file_local:
	EPAS=$(EPAS) SPROFILE='local' vagrant up --provision-with=generate_config_file

generate_config_file_remote:
	EPAS=$(EPAS) SPROFILE='remote' vagrant up --provision-with=generate_config_file
