#!/usr/bin/env perl

####################################################################################################################################
# Perl includes
####################################################################################################################################
use strict;
use warnings;
use File::Basename qw(dirname);
use File::Path qw(make_path);
use Getopt::Long qw(GetOptions);
use List::Util qw(any);
use Pod::Usage qw(pod2usage);
use YAML::XS qw(LoadFile DumpFile);

####################################################################################################################################
# Global vars
####################################################################################################################################
my $dbTypes = {
    'PG' => ['10', '11', '12', '13', '14'],
    'EPAS' => ['10', '11', '12', '13', '14']
};

my @supportedDockerImages = ('debian:9', 'debian:10', 'ubuntu:18.04', 'ubuntu:20.04', 'centos:7', 'centos:8', 'rockylinux:8');

####################################################################################################################################
# Usage
####################################################################################################################################

=head1 NAME

config.pl - generate configuration file

=head1 SYNOPSIS

config.pl [options]

 Cluster Options:
   --cluster-name       cluster name (a directory named after this name will be created in cluster path)
   --cluster-path       cluster path
   --extra-vars         additional cluster variables ('key=value key2=value2' format)

 Test Options:
   --architecture       target architecture
   --db-type            database type ('EPAS' or 'PG')
   --db-version         version of database

 Docker Options:
   --docker-image       docker base image name ('debian:9', 'debian:10', 'ubuntu:18.04', 'ubuntu:20.04', 'centos:7', 'centos:8', 'rockylinux:8')

 General Options:
   --help               display usage and exit
   --force              force configuration file update
=cut

####################################################################################################################################
# Command line parameters
####################################################################################################################################
my $bHelp = 0;
my $bForce = 0;
my $strArchitecture;
my $strClusterName;
my $strClusterPath;
my $strExtraVars;
my $strDbType;
my $strDbVersion;
my $strDockerImage;

GetOptions(
    'architecture=s' => \$strArchitecture,
    'cluster-name=s' => \$strClusterName,
    'cluster-path=s' => \$strClusterPath,
    'db-type=s' => \$strDbType,
    'db-version=s' => \$strDbVersion,
    'docker-image=s' => \$strDockerImage,
    'extra-vars=s' => \$strExtraVars,
    'force' => \$bForce,
    'help' => \$bHelp,
) or pod2usage( -exitval => 127 );
pod2usage() if $bHelp;

####################################################################################################################################
# Run in eval block to catch errors
####################################################################################################################################
eval{
    print("-------------------PROCESS START-------------------\n");
    print("INFO: config begin\n");
    die("cluster path must be provided") unless defined($strClusterPath);
    die("db type '$strDbType' not supported") if (defined($strDbType) and !defined($dbTypes->{$strDbType}));
    if(defined($strDbVersion)){
        die("db type must be provided when db version is provided") unless defined($strDbType);
        die("db type '$strDbType', version '$strDbVersion' not supported") unless (any { $_ eq $strDbVersion } @{$dbTypes->{$strDbType}});
    }
    die("docker image '$strDockerImage' not supported") unless !defined($strDockerImage) or (any { $_ eq $strDockerImage } @supportedDockerImages);

    # Validate architecture and load configuration file
    die("architecture must be provided") unless defined($strArchitecture);
    my $archConfFile = dirname($0)."/architectures/".$strArchitecture."/config.yml";
    die("architecture '$strArchitecture' not found") unless (-f $archConfFile);
    print("INFO: load '$archConfFile'\n");
    my $archConfig = LoadFile($archConfFile);

    # Modify cluster configuration
    $archConfig->{cluster_name} = $strClusterName if defined($strClusterName);
    $archConfig->{cluster_vars}->{pg_type} = $strDbType if defined($strDbType);
    $archConfig->{cluster_vars}->{pg_version} = $strDbVersion if defined($strDbVersion);
    $archConfig->{docker}->{image_name} = $strDockerImage if defined($strDockerImage);

    # Add extra cluster vars
    if(defined $strExtraVars and length $strExtraVars){
	$strExtraVars =~ s/^\s+|\s+$//g;
        foreach(split(/\s+/, $strExtraVars)){
            my ($key, $value) = split(/=/, $_);
            die("extra variables format must be 'key=value'") unless defined($key) and defined($value);
            $archConfig->{cluster_vars}->{$key} = $value;
        }
    }

    # Create cluster directory
    my $strClusterDir = $strClusterPath."/".$strClusterName;
    die("cluster directory already exists") if (-e $strClusterDir and !$bForce);
    if(! -e $strClusterDir){
        print("INFO: create cluster directory '$strClusterDir'\n");
        make_path($strClusterDir, { verbose => 1 }) or die("failed to create '$strClusterDir'");
    }
    print("INFO: write cluster configuration file\n");
    DumpFile($strClusterDir."/config.yml", $archConfig) or die("failed to write cluster configuration file");

    # Exit with success
    exit 0;
};
die("ERROR: test execution failed - $@\n") if $@;
