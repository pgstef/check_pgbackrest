%global _tag REL1_5

Name: nagios-plugins-pgbackrest
Version: 1.5
Release: 1
Summary: pgBackRest backup check plugin for Nagios 
License: PostgreSQL
Group: Applications/Databases
Url: https://github.com/dalibo/check_pgbackrest

Source0: https://github.com/dalibo/check_pgbackrest/archive/%{_tag}.tar.gz
BuildArch: noarch
BuildRoot: %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)
Requires: nagios-plugins
Requires: perl-JSON
Requires: perl-Net-SFTP-Foreign
Provides: check_pgbackrest = %{version}

%description
check_pgbackrest is designed to monitor pgBackRest backups from Nagios.

%prep
%setup -n check_pgbackrest-%{_tag}

%install
install -D -p -m 0755 check_pgbackrest %{buildroot}/%{_libdir}/nagios/plugins/check_pgbackrest

%files
%defattr(-,root,root,0755)
%{_libdir}/nagios/plugins/check_pgbackrest
%doc README LICENSE

%changelog
* Mon Mar 18 2019 Stefan Fercot <stefan.fercot@dalibo.com> 1.5-1
- new major release 1.5
