s1: clean create_vm pgbackrest_local
s2: clean create_vm pgbackrest_remote

create_vm:
	vagrant up

pgbackrest_local:
	vagrant up --provision-with=pgbackrest_local
	vagrant up --provision-with=icinga2_local

pgbackrest_remote:
	vagrant up --provision-with=pgbackrest_remote_primary
	vagrant up --provision-with=pgbackrest_remote_standby
	vagrant up --provision-with=icinga2_remote

clean:
	vagrant destroy -f