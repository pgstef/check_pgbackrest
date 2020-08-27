# Releasing

## Source code

Edit variable `$VERSION` in `check_pgbackrest`, and update the version field 
at the end of the in-line documentation in this script.

Use date format `LC_TIME=C date +"%a %b %d %Y"`.

In `check_pgbackrest.spec`:
  * update the tag in the `_tag` variable (first line)
  * update the version in `Version:`
  * edit the changelog

Update the `CHANGELOG.md` file too.

Update the tests results `test/regress/expected/version.out`.

## Documentation

Generate updated documentation:

```bash
pod2text check_pgbackrest > README
podselect check_pgbackrest > README.pod
```

## Tagging and building tar file

```bash
TAG=REL1_9
git tag -a $TAG -m "Release $TAG"
git tag
git push --tags
git archive --prefix=check_pgbackrest-$TAG/ -o /tmp/check_pgbackrest-1.9.tar.gz $TAG
```

## Release on github

  - Go to https://github.com/pgstef/check_pgbackrest/releases
  - Edit the release notes for the new tag
  - Set "check_pgbackrest $VERSION" as title, eg. "check_pgbackrest 1.9"
  - Here is the format of the release node itself:
    YYYY-MM-DD - Version X.Y
    
    Changelog:
      * item 1
      * item 2
      * ...
      
  - Upload the tar file
  - Save
  - Check or update https://github.com/pgstef/check_pgbackrest/releases

## Building the RPM file

The RPM file is provided by the PGDG community.

## Community

### pgsql-announce

Send a mail to the pgsql-announce mailing list. Eg.:

```
check_pgbackrest 1.9 has been released

check_pgbackrest is designed to monitor pgBackRest backups from Nagios, 
relying on the status information given by the "info" command.

It allows to monitor the backups retention and the consistency of the 
archived WAL segments.

Changes in check_pgbackrest 1.9:
  - ...
  - ...

===== Links & Credits =====

check_pgbackrest is an open project, licensed under the PostgreSQL license.
Any contribution to improve it is welcome.

Links:
  - Download: https://github.com/pgstef/check_pgbackrest/releases
  - Support: https://github.com/pgstef/check_pgbackrest/issues
```

### Submit a news on postgresql.org

* organisation: ---------
* Title: "check_pgbackrest 1.9 has been released"
* Content:
  
```
_Town, Country, Month xx, 2020_

`check_pgbackrest` is designed to monitor [pgBackRest](https://pgbackrest.org) 
backups from Nagios, relying on the status information given by the 
[info](https://pgbackrest.org/command.html#command-info) command.

It allows to monitor the backups retention and the consistency of the archived 
WAL segments.

Changes in check_pgbackrest 1.9
------------------------------------------------------------------------------

  * ...
  * ...

Links & Credits
--------------------------------------------------------------------------------
This is an open project, licensed under the PostgreSQL license. 
Any contribution to improve it is welcome.

Links:

  * [Download]: https://github.com/pgstef/check_pgbackrest/releases
  * [Support]: https://github.com/pgstef/check_pgbackrest/issues
```
  
* check "Related Open Source"