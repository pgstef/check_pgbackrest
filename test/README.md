# check_pgbackrest

## Introduction

This `Vagrantfile` is bootstrapping a fresh install with:
  * pgsql-srv hosting a pgsql cluster
  * pgBackRest installed and configured to backup and archive locally

## Testing

The easiest way to start testing is with the included `Makefile`.

_Build and Logon_:

```bash
cd test
make all
vagrant ssh -c "sudo /check_pgbackrest/test/regress/tests.bash"
```

## Tips

Find all existing VM created by vagrant on your system:

```bash
vagrant global-status
```

Shutdown all VM:

```bash
vagrant halt
```

Restart cluster:

```bash
vagrant up
```
