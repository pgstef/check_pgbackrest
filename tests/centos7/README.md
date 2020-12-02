# check_pgbackrest

## Introduction

This `Vagrantfile` is bootstrapping 3 possible test cases:

### 1. pgBackRest configured to backup and archive on a CIFS mount

  * `icinga-srv` executes check_pgbackrest by ssh with Icinga 2;
  * `pgsql-srv` hosting a primary pgsql cluster with pgBackRest installed;
  * `backup-srv` hosting the CIFS share;
  * pgBackRest backups are use to build a Streaming Replication with `backup-srv` as standby server.

Backups and archiving are done locally on `pgsql-srv` on the CIFS mount point.


### 2. pgBackRest configured to backup and archive remotely

  * `icinga-srv` executes check_pgbackrest by ssh with Icinga 2;
  * `pgsql-srv` hosting a primary pgsql cluster with pgBackRest installed;
  * `backup-srv` acting as pgBackRest repository host;
  * pgBackRest backups are use to build a Streaming Replication with `backup-srv` as standby server.

Backups of `pgsql-srv` are taken from `backup-srv`.
Archives are pushed from `pgsql-srv` to `backup-srv`.

### 3. pgBackRest configured to backup and archive to a MinIO S3 bucket

  * `icinga-srv` executes check_pgbackrest by ssh with Icinga 2;
  * `pgsql-srv` hosting a primary pgsql cluster with pgBackRest installed;
  * `backup-srv` hosting the MinIO server;
  * pgBackRest backups are use to build a Streaming Replication with `backup-srv` as standby server.

### 4. pgBackRest configured to backup and archive to an Azurite container

  * `icinga-srv` executes check_pgbackrest by ssh with Icinga 2;
  * `pgsql-srv` hosting a primary pgsql cluster with pgBackRest installed;
  * `backup-srv` hosting an Azurite docker container;
  * pgBackRest backups are use to build a Streaming Replication with `backup-srv` as standby server.

## Testing

The easiest way to start testing is with the included `Makefile`.

  * `s*`: pgBackRest installed from PGDG repository, Icinga 2 configured;
  * `s*_full`: build pgBackRest from sources, Icinga 2 configured;
  * `s*_light`: pgBackRest installed from PGDG repository, Icinga 2 not installed.

### Build

_Test case 1_:

```bash
make s1
```

_Test case 2_:

```bash
make s2
```

_Test case 3_:

```bash
make s3
```

_Test case 4_:

```bash
make s4
```

After each build, a `configuration.profile` file is generated.
This allows the various regress and activity scripts to adjust their settings
according to the test case built.

### Check the results of a manual execution

```bash
vagrant ssh pgsql-srv -c "sudo /check_pgbackrest/test/regress/test-01.bash"
```

### Simulate some activity

- pgbench activity, backup and local and remote restore:

```bash
vagrant ssh pgsql-srv -c "sudo /check_pgbackrest/tests/common/scripts/simulate-basic-activity.bash -s <scale> -a <activity_time>"
```

- corrupt some data pages and setup asynchronous archiving:

```bash
vagrant ssh pgsql-srv -c "sudo /check_pgbackrest/tests/common/scripts/simulate-extended-activity.bash"
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
