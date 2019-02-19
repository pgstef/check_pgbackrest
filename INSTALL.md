To handle the json output format of the pgBackRest info command, you need to
install the following module:

- on RedHat-like: `perl-JSON`
- on Debian-like: `libjson-perl` 


To list archived WALs using SFTP, you need to install the following module:

- On RedHat-like: `perl-Net-SFTP-Foreign`
- On Debian-like: `libnet-sftp-foreign-perl`

Remark: you might need to install the epel-release package too.