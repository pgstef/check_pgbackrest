# Validation process

## PostgreSQL

```bash
# Test case 1
time sudo make s1_light
time sudo vagrant ssh pgsql-srv -c "sudo /check_pgbackrest/tests/common/scripts/simulate-basic-activity.bash -s 10 -a 10"
time sudo vagrant ssh pgsql-srv -c "sudo /check_pgbackrest/tests/common/regress/test-01.bash -s -P /check_pgbackrest"

# Test case 2
time sudo make s2_light
time sudo vagrant ssh pgsql-srv -c "sudo /check_pgbackrest/tests/common/scripts/simulate-basic-activity.bash -s 10 -a 10"
time sudo vagrant ssh pgsql-srv -c "sudo /check_pgbackrest/tests/common/regress/test-01.bash -s -P /check_pgbackrest"

# Test case 3
time sudo make s3_light
time sudo vagrant ssh pgsql-srv -c "sudo /check_pgbackrest/tests/common/scripts/simulate-basic-activity.bash -s 10 -a 10"
time sudo vagrant ssh pgsql-srv -c "sudo /check_pgbackrest/tests/common/regress/test-01.bash -s -P /check_pgbackrest"

# Test case 4
time sudo make s4_light
time sudo vagrant ssh pgsql-srv -c "sudo /check_pgbackrest/tests/common/scripts/simulate-basic-activity.bash -s 10 -a 10"
time sudo vagrant ssh pgsql-srv -c "sudo /check_pgbackrest/tests/common/regress/test-01.bash -s -P /check_pgbackrest"
```

## EDB Postgres Advanced Server

```bash
# Test case 1
time sudo make EPAS='true' s1_light
time sudo vagrant ssh pgsql-srv -c "sudo /check_pgbackrest/tests/common/scripts/simulate-basic-activity.bash -s 10 -a 10"
time sudo vagrant ssh pgsql-srv -c "sudo /check_pgbackrest/tests/common/regress/test-01.bash -s -P /check_pgbackrest"

# Test case 2
time sudo make EPAS='true' s2_light
time sudo vagrant ssh pgsql-srv -c "sudo /check_pgbackrest/tests/common/scripts/simulate-basic-activity.bash -s 10 -a 10"
time sudo vagrant ssh pgsql-srv -c "sudo /check_pgbackrest/tests/common/regress/test-01.bash -s -P /check_pgbackrest"

# Test case 3
time sudo make EPAS='true' s3_light
time sudo vagrant ssh pgsql-srv -c "sudo /check_pgbackrest/tests/common/scripts/simulate-basic-activity.bash -s 10 -a 10"
time sudo vagrant ssh pgsql-srv -c "sudo /check_pgbackrest/tests/common/regress/test-01.bash -s -P /check_pgbackrest"

# Test case 4
time sudo make EPAS='true' s4_light
time sudo vagrant ssh pgsql-srv -c "sudo /check_pgbackrest/tests/common/scripts/simulate-basic-activity.bash -s 10 -a 10"
time sudo vagrant ssh pgsql-srv -c "sudo /check_pgbackrest/tests/common/regress/test-01.bash -s -P /check_pgbackrest"
```
