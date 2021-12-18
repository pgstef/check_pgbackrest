## Zabbix

Template is tested with Zabbix 5.4 and Zabbix Agent 5.4 or Zabbix Agent2

## Installation
### check_pgbackrest

Place it in /opt/zabbix/
change owner of directory and script to zabbix user/group as per your system settings

### crontab
Place below line into root crontab. It will execute stanza discovery once a day.

```
0 0 * * * /bin/bash /opt/zabbix/check_pgbackrest_discovery.sh | zabbix_sender -c /etc/zabbix/zabbix_agent2.conf -i -
```

### userparameter
Put to either separate userparameter file or zabbix agent config file.
```
UserParameter=pgbackrest_check[*],sudo perl /opt/zabbix/check_pgbackrest -s archives -S $1 -O json
```

### sudo
Script is executed by zabbix user and it works with pgbackrest which requires root, we need to allow sudo for zabbix agent. 

SECURITY! Below line will work but allow zabbix user to execute any command without password, use on your own risk. !

```
zabbix ALL = (root) NOPASSWD:ALL
```

### template
Just import template into Zabbix server and assign to host, for faster results, run discovery manually.
Template name is t_pgbackrest.