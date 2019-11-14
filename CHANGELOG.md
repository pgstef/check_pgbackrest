Changelog
=========

2019-xx-xx v1.6:

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