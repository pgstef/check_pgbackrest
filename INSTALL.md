To handle the json output format of the pgBackRest info command, you need to
install the following module:

- on RedHat-like: `perl-JSON`
- on Debian-like: `libjson-perl` 


To list archived WALs using SFTP, you need to install the following module:

- On RedHat-like: `perl-Net-SFTP-Foreign`
- On Debian-like: `libnet-sftp-foreign-perl`


To install check_pgbackrest with the provided rpm file:

```
yum install -y epel-release
yum install -y nagios-plugins-pgbackrest-*.noarch.rpm
```

The rpm will also require nagios-plugins to be installed and put the 
`check_pgbackrest` script there. 
That's why the epel-release package is needed too.