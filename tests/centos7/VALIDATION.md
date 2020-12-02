# Validation process

## PostgreSQL

```bash
# Test case 1
time sudo make s1
time sudo vagrant ssh pgsql-srv -c "sudo /check_pgbackrest/tests/common/scripts/simulate-basic-activity.bash -s 10 -a 10"
time sudo vagrant ssh pgsql-srv -c "sudo /check_pgbackrest/tests/common/regress/test-01.bash -s -P /check_pgbackrest"
time sudo vagrant ssh icinga-srv -c "sudo icingacli monitoring list services --service=pgbackrest* --verbose"

# Test case 2
time sudo make s2
time sudo vagrant ssh pgsql-srv -c "sudo /check_pgbackrest/tests/common/scripts/simulate-basic-activity.bash -s 10 -a 10"
time sudo vagrant ssh pgsql-srv -c "sudo /check_pgbackrest/tests/common/regress/test-01.bash -s -P /check_pgbackrest"
time sudo vagrant ssh icinga-srv -c "sudo icingacli monitoring list services --service=pgbackrest* --verbose"

# Test case 3
time sudo make s3
time sudo vagrant ssh pgsql-srv -c "sudo /check_pgbackrest/tests/common/scripts/simulate-basic-activity.bash -s 10 -a 10"
time sudo vagrant ssh pgsql-srv -c "sudo /check_pgbackrest/tests/common/regress/test-01.bash -s -P /check_pgbackrest"
time sudo vagrant ssh icinga-srv -c "sudo icingacli monitoring list services --service=pgbackrest* --verbose"

# Test case 4
time sudo make s4
time sudo vagrant ssh pgsql-srv -c "sudo /check_pgbackrest/tests/common/scripts/simulate-basic-activity.bash -s 10 -a 10"
time sudo vagrant ssh pgsql-srv -c "sudo /check_pgbackrest/tests/common/regress/test-01.bash -s -P /check_pgbackrest"
time sudo vagrant ssh icinga-srv -c "sudo icingacli monitoring list services --service=pgbackrest* --verbose"
```

## EDB Postgres Advanced Server

```bash
# Test case 1
time sudo make EPAS='true' s1
time sudo vagrant ssh pgsql-srv -c "sudo /check_pgbackrest/tests/common/scripts/simulate-basic-activity.bash -s 10 -a 10"
time sudo vagrant ssh pgsql-srv -c "sudo /check_pgbackrest/tests/common/regress/test-01.bash -s -P /check_pgbackrest"
time sudo vagrant ssh icinga-srv -c "sudo icingacli monitoring list services --service=pgbackrest* --verbose"

# Test case 2
time sudo make EPAS='true' s2
time sudo vagrant ssh pgsql-srv -c "sudo /check_pgbackrest/tests/common/scripts/simulate-basic-activity.bash -s 10 -a 10"
time sudo vagrant ssh pgsql-srv -c "sudo /check_pgbackrest/tests/common/regress/test-01.bash -s -P /check_pgbackrest"
time sudo vagrant ssh icinga-srv -c "sudo icingacli monitoring list services --service=pgbackrest* --verbose"

# Test case 3
time sudo make EPAS='true' s3
time sudo vagrant ssh pgsql-srv -c "sudo /check_pgbackrest/tests/common/scripts/simulate-basic-activity.bash -s 10 -a 10"
time sudo vagrant ssh pgsql-srv -c "sudo /check_pgbackrest/tests/common/regress/test-01.bash -s -P /check_pgbackrest"
time sudo vagrant ssh icinga-srv -c "sudo icingacli monitoring list services --service=pgbackrest* --verbose"

# Test case 4
time sudo make EPAS='true' s4
time sudo vagrant ssh pgsql-srv -c "sudo /check_pgbackrest/tests/common/scripts/simulate-basic-activity.bash -s 10 -a 10"
time sudo vagrant ssh pgsql-srv -c "sudo /check_pgbackrest/tests/common/regress/test-01.bash -s -P /check_pgbackrest"
time sudo vagrant ssh icinga-srv -c "sudo icingacli monitoring list services --service=pgbackrest* --verbose"
```
