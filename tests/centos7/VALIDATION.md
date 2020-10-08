# Validation process

## PostgreSQL

```bash
time sudo make s1_light
time sudo vagrant ssh pgsql-srv -c "sudo /check_pgbackrest/tests/common/scripts/simulate-basic-activity.bash -s 10 -a 10"
time sudo vagrant ssh pgsql-srv -c "sudo /check_pgbackrest/tests/common/regress/test-s1.bash -s -p /check_pgbackrest"
time sudo vagrant ssh pgsql-srv -c "sudo /check_pgbackrest/tests/common/regress/test-s1.bash -s -p /check_pgbackrest -a '--enable-internal-pgbr-cmds'"
```

```bash
time sudo make s2_light
time sudo vagrant ssh pgsql-srv -c "sudo /check_pgbackrest/tests/common/scripts/simulate-basic-activity.bash -s 10 -a 10"
time sudo vagrant ssh pgsql-srv -c "sudo /check_pgbackrest/tests/common/regress/test-s2-from-primary.bash -s -p /check_pgbackrest"
time sudo vagrant ssh pgsql-srv -c "sudo /check_pgbackrest/tests/common/regress/test-s2-from-primary.bash -s -p /check_pgbackrest -a '--enable-internal-pgbr-cmds'"
```

```bash
time sudo make s3_light
time sudo vagrant ssh pgsql-srv -c "sudo /check_pgbackrest/tests/common/scripts/simulate-basic-activity.bash -s 10 -a 10"
time sudo vagrant ssh pgsql-srv -c "sudo /check_pgbackrest/tests/common/regress/test-s3.bash -s -p /check_pgbackrest"
time sudo vagrant ssh pgsql-srv -c "sudo /check_pgbackrest/tests/common/regress/test-s3.bash -s -p /check_pgbackrest -a '--enable-internal-pgbr-cmds'"
```

## EDB Postgres Advanced Server

```bash
time sudo make EPAS='true' s1_full
time sudo vagrant ssh pgsql-srv -c "sudo /check_pgbackrest/tests/common/scripts/simulate-basic-activity.bash -s 10 -a 10"
time sudo vagrant ssh pgsql-srv -c "sudo /check_pgbackrest/tests/common/regress/test-s1.bash -s -p /check_pgbackrest"
time sudo vagrant ssh pgsql-srv -c "sudo /check_pgbackrest/tests/common/regress/test-s1.bash -s -p /check_pgbackrest -a '--enable-internal-pgbr-cmds'"
```

```bash
time sudo make EPAS='true' s2_full
time sudo vagrant ssh pgsql-srv -c "sudo /check_pgbackrest/tests/common/scripts/simulate-basic-activity.bash -s 10 -a 10"
time sudo vagrant ssh pgsql-srv -c "sudo /check_pgbackrest/tests/common/regress/test-s2-from-primary.bash -s -p /check_pgbackrest"
time sudo vagrant ssh pgsql-srv -c "sudo /check_pgbackrest/tests/common/regress/test-s2-from-primary.bash -s -p /check_pgbackrest -a '--enable-internal-pgbr-cmds'"
```

```bash
time sudo make EPAS='true' s3_full
time sudo vagrant ssh pgsql-srv -c "sudo /check_pgbackrest/tests/common/scripts/simulate-basic-activity.bash -s 10 -a 10"
time sudo vagrant ssh pgsql-srv -c "sudo /check_pgbackrest/tests/common/regress/test-s3.bash -s -p /check_pgbackrest"
time sudo vagrant ssh pgsql-srv -c "sudo /check_pgbackrest/tests/common/regress/test-s3.bash -s -p /check_pgbackrest -a '--enable-internal-pgbr-cmds'"
```

## Check icinga2 services with full builds

```bash
sudo vagrant ssh icinga-srv -c "sudo icingacli monitoring list services --service=pgbackrest* --verbose"
```