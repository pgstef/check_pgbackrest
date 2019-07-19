# check_pgbackrest

## Introduction

This `Vagrantfile` is bootstrapping 3 possible test cases:

### 1. pgBackRest configured to backup and archive locally

  * `icinga-srv` executes check_pgbackrest by ssh with Icinga 2;
  * `pgsql-srv` hosting a pgsql cluster with pgBackRest installed;
  * `backup-srv` not used, clean pgsql cluster running on it.

Backups and archiving are done locally on `pgsql-srv`.

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

### Test case 1

_Build_:

```bash
cd test
make s1
```

Expected make time: 6 min.

_Check the results of a manual execution of check_pgbackrest_:

```bash
vagrant ssh pgsql-srv -c "sudo /check_pgbackrest/test/regress/test-s1.bash"
```

Expected run time: 15 sec.

_To simulate some activity with pgBackRest_:

```bash
vagrant ssh pgsql-srv -c "sudo /check_pgbackrest/test/regress/simulate-activity-local.bash"
```

Modify `SCALE` factor or `ACTIVITY_TIME` in this script to simulate more activity.

### Test case 2

_Build_:

```bash
cd test
make s2
```

Expected make time: 7 min.

_Check the results of a manual execution of check_pgbackrest_:

```bash
vagrant ssh pgsql-srv -c "sudo /check_pgbackrest/test/regress/test-s2-from-primary.bash"
```

Expected run time: 30 sec.

### Test case 3

_Build_:

```bash
cd test
make s3
```

Expected make time: 8 min.

_Check the results of a manual execution of check_pgbackrest_:

```bash
vagrant ssh pgsql-srv -c "sudo /check_pgbackrest/test/regress/test-s3.bash"
```

Expected run time: 45 sec.

_To simulate some activity with pgBackRest_:

```bash
vagrant ssh pgsql-srv -c "sudo /check_pgbackrest/test/regress/simulate-activity-local.bash"
```

Modify `SCALE` factor or `ACTIVITY_TIME` in this script to simulate more activity.

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

### Generate expected regress test results

Edit the `test-*.bash` scripts and set `GENERATE_EXPECTED` to true. Run it.

Currently, expected tests results are the same for test cases 1 and 2.

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
