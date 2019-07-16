all: clean_before create_vm clean_after

clean_before:
	vagrant destroy -f

create_vm:
	vagrant up

clean_after:
	vagrant destroy -f