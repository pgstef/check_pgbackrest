# check_pgbackrest

## Introduction

This `Vagrantfile` is bootstrapping 3 possible test cases:

### 1. pgBackRest configured to backup and archive on a CIFS mount

  * `icinga-srv` executes check_pgbackrest by ssh with Icinga 2;
  * `pgsql-srv` hosting a pgsql cluster with pgBackRest installed;
  * `backup-srv` hosting the CIFS share.

Backups and archiving are done locally on `pgsql-srv` on the CIFS mount point.

### 2. pgBackRest configured to backup and archive remotely

  * `icinga-srv` executes check_pgbackrest by ssh with Icinga 2;
  * `pgsql-srv` hosting a pgsql cluster with pgBackRest installed;
  * `backup-srv` hosting the pgBackRest backups and archives.

Backups of `pgsql-srv` are taken from `backup-srv`. 
Archives are pushed from `pgsql-srv` to `backup-srv`.
Checks (retention and archives) are done both locally (on `backup-srv`) and 
remotely (on `pgsql-srv`). Checks are performed from `icinga-srv` by ssh.
pgBackRest backups are use to build a Streaming Replication with `backup-srv` 
as standby server.

### 3. pgBackRest configured to backup and archive to a MinIO S3 bucket

  * `icinga-srv` executes check_pgbackrest by ssh with Icinga 2;
  * `pgsql-srv` hosting a pgsql cluster with pgBackRest installed;
  * `backup-srv` hosting the MinIO server.

## Testing

The easiest way to start testing is with the included `Makefile`.

  * `s*`: pgBackRest installed from PGDG repository, Icinga 2 configured;
  * `s*_full`: build pgBackRest from sources, Icinga 2 configured;
  * `s*_light`: pgBackRest installed from PGDG repository, Icinga 2 not installed.

### Test case 1

_Build_:

```bash
cd test
make s1
```

_Check the results of a manual execution of check_pgbackrest_:

```bash
vagrant ssh pgsql-srv -c "sudo /check_pgbackrest/test/regress/test-s1.bash"
```

### Test case 2

_Build_:

```bash
cd test
make s2
```

_Check the results of a manual execution of check_pgbackrest_:

```bash
vagrant ssh pgsql-srv -c "sudo /check_pgbackrest/test/regress/test-s2-from-primary.bash"
```

### Test case 3

_Build_:

```bash
cd test
make s3
```

_Check the results of a manual execution of check_pgbackrest_:

```bash
vagrant ssh pgsql-srv -c "sudo /check_pgbackrest/test/regress/test-s3.bash"
```

### Simulate some activity:

Use the following script:

```bash
vagrant ssh pgsql-srv -c "sudo /check_pgbackrest/tests/common/scripts/simulate-basic-activity.bash -s <scale> -a <activity_time>"
```

### Icinga 2 connectivity

_Check the results of _check_pgbackrest_ launched by Icinga 2:

```bash
vagrant ssh icinga-srv -c "sudo icingacli monitoring list services --service=pgbackrest* --verbose"
```

_Navigate to Icinga Web 2_:

Get the IP address of `icinga-srv` with:

```bash
vagrant ssh icinga-srv -c "ip addr show eth0"
```

And then go to `http://IP/icingaweb2`. Credentials are `icingaweb / icingaweb`.

### Clean up

Don't forget to clean the VM's after the tests:

```bash
make clean
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

Restart the halted cluster:

```bash
vagrant up
```
