# Releasing

## Source code

Edit variable `$VERSION` in `check_pgbackrest`, and update the version field at
the end of the inline documentation in this script.

## Documentation

Generate updated documentation :
```
pod2text check_pgbackrest > README
podselect check_pgbackrest > README.pod
```
