all: create_vm pgbackrest_local check_pgbackrest

create_vm:
	vagrant up

pgbackrest_local:
	vagrant up --provision-with=pgbackrest_local

check_pgbackrest:
	vagrant up --provision-with=check_pgbackrest

clean:
	vagrant destroy -f