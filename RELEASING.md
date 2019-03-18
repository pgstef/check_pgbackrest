# Releasing

## Source code

Edit variable `$VERSION` in `check_pgbackrest`, and update the version field at
the end of the in-line documentation in this script.

Use date format `LC_TIME=C date +"%a %b %d %Y"`.

## Documentation

Generate updated documentation :
```
pod2text check_pgbackrest > README
podselect check_pgbackrest > README.pod
```

## Tagging and building tar file

```
TAG=REL1_5
git tag -a $TAG -m "Release $TAG"
git tag
git push --tags
git archive --prefix=check_pgbackrest-$TAG/ -o /tmp/check_pgbackrest-$TAG.tgz $TAG
```
