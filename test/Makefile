s1: clean create_vm pgbackrest_local icinga2_local
s1_light: clean create_vm pgbackrest_local
s2: clean create_vm pgbackrest_remote icinga2_remote
s2_light: clean create_vm pgbackrest_remote
s3: clean create_vm pgbackrest_minio icinga2_minio
s3_light: clean create_vm pgbackrest_minio

create_vm:
	vagrant up

pgbackrest_local:
	vagrant up --provision-with=cifs
	vagrant up --provision-with=pgbackrest_local

icinga2_local:
	vagrant up --provision-with=icinga2
	vagrant up --provision-with=icinga2_local

pgbackrest_remote:
	vagrant up --provision-with=pgbackrest_remote_primary
	vagrant up --provision-with=pgbackrest_remote_standby

icinga2_remote:
	vagrant up --provision-with=icinga2
	vagrant up --provision-with=icinga2_remote

pgbackrest_minio:
	vagrant up --provision-with=minio
	vagrant up --provision-with=minio_http
	vagrant up --provision-with=pgbackrest_minio

icinga2_minio:
	vagrant up --provision-with=icinga2
	vagrant up --provision-with=icinga2_minio

clean:
	vagrant destroy -f