## RPM

To install check_pgbackrest with the provided rpm file:

```
yum install -y epel-release
yum install -y nagios-plugins-pgbackrest-*.noarch.rpm
```

The rpm will also require nagios-plugins to be installed and put the 
`check_pgbackrest` script there. 
That's why the epel-release package is needed too.

The provided rpm doesn't install the modules needed for Amazon S3 compatibility. 
See below which modules to install manually.


## Manual installation

To handle the json output format of the pgBackRest info command, you need to
install the following module:

- on RedHat-like: `perl-JSON`
- on Debian-like: `libjson-perl` 

To list archived WALs using SFTP, you need to install the following module:

- On RedHat-like: `perl-Net-SFTP-Foreign`
- On Debian-like: `libnet-sftp-foreign-perl`

The Data::Dump perl module is also needed:

- On RedHat-like: `perl-Data-Dumper`
- On Debian-like: `libdata-dump-perl`


## Amazon S3 compatibility

To handle the S3 connection, two modules are needed:

- On RedHat-like: `perl-Config-IniFiles` and `perl-Net-Amazon-S3`
- On Debian-like: `libconfig-inifiles-perl` and `libnet-amazon-s3-perl`

Unfortunately, the `perl-Net-Amazon-S3` (on CentOS 7) can, for the time being, 
only be found in the Open Fusion repositories. To install it on CentOS 7, use:

```
yum install -y http://repo.openfusion.net/centos7-x86_64/\
openfusion-release-0.7-1.of.el7.noarch.rpm
```

## Unneeded Perl dependencies with pgBackRest >= 2.28

Using the `--enable-internal-pgbr-cmds` argument will use pgBackRest internal
commands. SFTP or Amazon S3 specific Perl dependencies are then not needed
anymore.