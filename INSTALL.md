## Manual installation

To handle the json output format of the pgBackRest info command, you need to
install the following module:

- on RedHat-like: `perl-JSON`
- on Debian-like: `libjson-perl` 

The Data::Dump perl module is also needed:

- On RedHat-like: `perl-Data-Dumper`
- On Debian-like: `libdata-dump-perl`

On RedHat-like systems the following additional Perl modules are needed:

- `perl-File-Find`
- `perl-FindBin`
- `perl-Math-BigInt`
- `perl-Math-Complex` 

-----

## PGDG packages

### RPM

To install check_pgbackrest using the PGDG repositories:

```
yum install -y epel-release
yum install -y nagios-plugins-pgbackrest
```

The rpm will also require nagios-plugins to be installed and put the 
`check_pgbackrest` script there. 
That's why the epel-release package is needed too.

### DEB

To install check_pgbackrest using the PGDG repositories (located in `/usr/bin`):

```
apt-get -y install check-pgbackrest
```
