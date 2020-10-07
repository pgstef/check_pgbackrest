#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

PGUSER="$1"

# add check_pgbackrest tests
cat <<EOF >>/etc/icinga2/conf.d/hosts.conf

/* retention service should work on both primary and standby */
object CheckCommand "by_ssh_pgbackrest_retention" {
  import "by_ssh"
  vars.by_ssh_command = "/usr/lib64/nagios/plugins/check_pgbackrest --stanza=\$stanza$ --service=retention --retention-full=\$retention_full$ --prefix=\"\$prefix$\""
}

object Service "pgbackrest_retention" {
  import "generic-service"
  host_name = "pgsql-srv"
  check_command = "by_ssh_pgbackrest_retention"
  vars.by_ssh_logname = "accessed_by_ssh"

  vars.stanza = "my_stanza"
  vars.retention_full = 1
  vars.prefix = "sudo -u $PGUSER"
}

object Service "pgbackrest_retention" {
  import "generic-service"
  host_name = "backup-srv"
  check_command = "by_ssh_pgbackrest_retention"
  vars.by_ssh_logname = "accessed_by_ssh"

  vars.stanza = "my_stanza"
  vars.retention_full = 1
  vars.prefix = "sudo -u $PGUSER"
}

/* check archives locally on standby */
object CheckCommand "by_ssh_pgbackrest_archives" {
  import "by_ssh"
  vars.by_ssh_command = "/usr/lib64/nagios/plugins/check_pgbackrest --stanza=\$stanza$ --service=archives --repo-path=\$repo_path$ --prefix=\"\$prefix$\""
}

object Service "pgbackrest_archives" {
  import "generic-service"
  host_name = "backup-srv"
  check_command = "by_ssh_pgbackrest_archives"
  vars.by_ssh_logname = "accessed_by_ssh"

  vars.stanza = "my_stanza"
  vars.repo_path = "/var/lib/pgbackrest/archive"
  vars.prefix = "sudo -u $PGUSER"
}

/* check archives remotely from primary */
object CheckCommand "by_ssh_pgbackrest_archives_remote" {
  import "by_ssh"
  vars.by_ssh_command = "/usr/lib64/nagios/plugins/check_pgbackrest --stanza=\$stanza$ --service=archives --repo-path=\$repo_path$ --prefix=\"\$prefix$\" --repo-host=\$repo_host$ --repo-host-user=\$repo_host_user$"
}

object Service "pgbackrest_archives" {
  import "generic-service"
  host_name = "pgsql-srv"
  check_command = "by_ssh_pgbackrest_archives_remote"
  vars.by_ssh_logname = "accessed_by_ssh"

  vars.stanza = "my_stanza"
  vars.repo_path = "/var/lib/pgbackrest/archive"
  vars.prefix = "sudo -u $PGUSER"
  vars.repo_host = "backup-srv"
  vars.repo_host_user = "$PGUSER"
}
EOF

systemctl restart icinga2

# show
icingacli monitoring list services --service=pgbackrest* --verbose