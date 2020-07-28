# Validation process

```bash
time sudo make s1_light
time sudo vagrant ssh pgsql-srv -c "sudo /check_pgbackrest/test/regress/simulate-extended-activity.bash -s 10 -a 10 -p local"
time sudo vagrant ssh pgsql-srv -c "sudo /check_pgbackrest/test/regress/test-s1.bash -s -p /check_pgbackrest"
time sudo vagrant ssh pgsql-srv -c "sudo /check_pgbackrest/test/regress/test-s1.bash -s -p /check_pgbackrest -a '--enable-internal-pgbr-cmds'"
```

```bash
time sudo make s2_light
time sudo vagrant ssh pgsql-srv -c "sudo /check_pgbackrest/test/regress/simulate-extended-activity.bash -s 10 -a 10 -p remote"
time sudo vagrant ssh pgsql-srv -c "sudo /check_pgbackrest/test/regress/test-s2-from-primary.bash -s -p /check_pgbackrest"
time sudo vagrant ssh pgsql-srv -c "sudo /check_pgbackrest/test/regress/test-s2-from-primary.bash -s -p /check_pgbackrest -a '--enable-internal-pgbr-cmds'"
```

```bash
time sudo make s3_light
time sudo vagrant ssh pgsql-srv -c "sudo /check_pgbackrest/test/regress/simulate-extended-activity.bash -s 10 -a 10 -p local"
time sudo vagrant ssh pgsql-srv -c "sudo /check_pgbackrest/test/regress/test-s3.bash -s -p /check_pgbackrest"
time sudo vagrant ssh pgsql-srv -c "sudo /check_pgbackrest/test/regress/test-s3.bash -s -p /check_pgbackrest -a '--enable-internal-pgbr-cmds'"
```