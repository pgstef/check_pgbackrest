# Performance profiling

## Introduction

In this module, the `Devel::NYTProf` Perl source code profiler is used to 
analyze the performance of `check_pgbackrest`.

For each test case scenario, the scripts will:
  * loop `LOOP_NB` times;
  * generate `WAL_GENERATED_PER_LOOP` WAL archives in each loop;
  * execute the `--service=retention --retention-full` command with NYTProf;
  * execute `--service=archives --repo-path`;
  * generate HTML reports with `nytprofhtml` for the first and last loops.

To modify the behavior of the scripts, edit the following parameters:

```bash
LOOP_NB=10
WAL_GENERATED_PER_LOOP=20
SECONDS_TO_WAIT_AFTER_LOOP=3
```

A `nytprof` directory should be present in the `test/perf` directory once the 
performance test has been run, containing the `nytprofhtml` results.

## Testing

### Test case 1

Should be performed after scenario 1 has been built:

```bash
vagrant ssh pgsql-srv -c "sudo /check_pgbackrest/test/perf/perf-test-s1.bash"
```

### Test case 2

Should be performed after scenario 2 has been built:

```bash
vagrant ssh pgsql-srv -c "sudo /check_pgbackrest/test/perf/perf-test-s2-from-primary.bash"
```

### Test case 3

Should be performed after scenario 3 has been built:

```bash
vagrant ssh pgsql-srv -c "sudo /check_pgbackrest/test/perf/perf-test-s3.bash"
```
