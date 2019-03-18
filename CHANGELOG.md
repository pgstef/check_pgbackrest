Changelog
=========

2019-xx-xx v1.5:

  - Order archived WALs list by filename to validate if none is missing.
  - Add --debug option to print some debug messages.
  - Add ignore-archived-since argument to ignore the archived WALs since the 
  provided interval.
  - Add --latest-archive-age-alert to define the max age of the latest 
  archived WAL before raising a critical alert.