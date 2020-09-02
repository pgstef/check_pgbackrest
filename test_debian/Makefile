all: clean create_vm pgbackrest_local

create_vm:
	vagrant up

pgbackrest_local:
	vagrant up --provision-with=pgbackrest_local
	vagrant up --provision-with=check_pgbackrest

clean:
	vagrant destroy -f