Changelog
=========

2024-XX-XX v2.4:

  - Only support pgBackRest **2.52** and above to fix issue with new pgBackRest
  versioning policy since `2.52.1`. (Reported by netphantm)
  - Add new `pgbackrest_version` service, in order to check for a specific
  pgBackRest target version.

2022-05-31 v2.3:

  - In case of pgBackRest db history change (after a successful `stanza-upgrade`),
  only the latest database system/version will be checked.
  (Reported by Hendrik Schöffmann)
  - Check if boundary WALs could be defined from history files in case of
  timeline switches.
  - Fix timeline switch detection from history files. (Reported by martindomeij)
  - Add `list-boundaries` option to debug print the boundary WALs fetched from
  the history files.
  - Eval pgBackRest JSON output in case of invalid config option would trigger
  warnings. (Reported by Manuel Alonso)

2021-12-06 v2.2:

  - The retention service will check if any error was detected during the backup
  (reported since pgBackRest 2.36).
  - Add nagios_strict output format to filter out unsupported types of values
  from performance data. (Reported by netphantm and Adrien Nayrat)
  - Support uncompressed files in the archives service. (Suggested by
  Jean-Philippe Guérard)
  - Add `retention-diff` and `retention-incr` options in the retention service.
  (Contributed by devopstales).
  - Add `retention-age-to-oldest` option in the retention service. (Suggested by
  Hendrik Schöffmann)

2021-09-21 v2.1:

  - Only support pgBackRest **2.33** and above in order to add support for the
  multi-repository feature.
  Introduce the `--repo` option to set the repository index to operate on.
  When multiple repositories will be found, if the `--repo` argument is not
  provided, the services will operate on all repositories defined, checking for
  inconsistencies across multiple repositories.
  It is however recommended to also define checks using the `--repo` argument to
  verify the sanity of each repository separately. (Reviewed by Adrien Nayrat)
  - Add a new `max-archives-check-number` option for the archives service.
  This is intended to use in case of timeline switch and when boundary WAL can't
  be detected properly, in order to prevent infinite WAL archives check.
  - Add `prtg` output format (Hans-Peter Zahno).

2021-02-10 v2.0:

  - Only support pgBackRest **2.32** and above in order to only use its internal
  commands. This remove Perl dependencies no-longer needed to reach repository 
  hosts or S3 compatible object stores.
  This also brings Azure compatible object stores support.
  The `repo-*` arguments have then been deprecated.
  - Support non-gz compressed files in the archives check (Magnus Hagander).
  - Fix the `ignore-archived-*` features when using pgBackRest internal commands 
  (Magnus Hagander).
  - Improve `ignore-archived-*` features to skip WAL consistency check for backups
  involving ignored archives.
  - Skip unneeded boundary WAL check on TL switch (reported by sebastienruiz). 
  - The retention service will now check that at least the backup directory exists,
  not only trusting the pgBackRest info command output (suggested by Michael Banck).

2020-07-28 v1.9:

  - The archives service will now only look at the archives listed between 
  the oldest backup start archive and the max WAL returned by the pgBackRest 
  info command. This should avoid unnecessary alerts. 
  To extend the check to all the archives found, the new --extended-check 
  argument has been implemented (suggested by blogh).
  - Remove refresh of pgBackRest info return after getting the archives list. 
  That avoids CRITICAL alert if an archive is generated between those two steps. 
  Instead, a WARNING message "max WAL is not the latest archive" will be 
  displayed (suggested by blogh).
  - Fix S3 archives detection (reported by khadijahvf).
  - New enable-internal-pgbr-cmds argument, for pgBackRest >= 2.28. Internal
  pgBackRest commands will then be used to list and get the content of files
  in the repository instead of Perl specific drivers. This is, for instance,
  needed to access encrypted repositories. This should become the default and
  only access method in the next release, removing some Perl dependencies.

2020-03-16 v1.8:

  - Change output of missing archives. The complete list is now only shown in 
  --debug mode (suggested by Guillaume Lelarge).
  - Add --list-archives argument to print the list of all the archived WAL 
  segments.

2020-01-14 v1.7:

  - Rename --format argument to --output.
  - Add json output format.
  - Add timing debug information.
  - Improve performance of the needed wal list check.

2019-11-14 v1.6:

  - Check for each backup its needed archived WALs based on wal start/stop 
  information given by the pgBackRest "info" command.
  - Return WARNING instead of CRITICAL in case of missing archived WAL prior 
  to latest backup, regardless its type.
  - Add ignore-archived-before argument to ignore the archived WALs before the 
  provided interval.
  - Rename ignore-archived-since argument to ignore-archived-after.
  - Add --retention-age-to-full argument to check the latest full backup age.
  - Fix bad behavior on CIFS mount (reported by `renesepp`).
  - Add Amazon s3 support for archives service (Andrew E. Bruno).
  - Avoid chdir when scanning a directory to avoid some problems with 
  `sudo -u` (Christophe Courtois).
  - New check_pgb_version service (suggested by Christophe Courtois).

2019-03-18 v1.5:

  - Order archived WALs list by filename to validate if none is missing.
  - Add --debug option to print some debug messages.
  - Add ignore-archived-since argument to ignore the archived WALs since the 
  provided interval.
  - Add --latest-archive-age-alert to define the max age of the latest 
  archived WAL before raising a critical alert.
