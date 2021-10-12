# README

<!--
(\_/)
( •_•)
/ > 🐘
-->

---

## Introduction

This _Test Suite_ is based on the [edb-ansible](https://github.com/EnterpriseDB/edb-ansible) Ansible Collection. It deploys docker containers and typical architectures.

It tends to support the following situations:
* Directly-attached storage - [Use Case 1](https://www.enterprisedb.com/docs/supported-open-source/pgbackrest/06-use_case_1/)
* Dedicated repository host - [Use Case 2](https://www.enterprisedb.com/docs/supported-open-source/pgbackrest/07-use_case_2)

---

## GitHub Actions

[GitHub Actions](../.github/workflows/main.yml) are testing:
  * Use-Case 1: PG 14, CentOS 7, using pgBackRest PGDG packages
  * Use-Case 2: PG 13, Ubuntu 20.04, using pgBackRest PGDG packages

---

## Vagrant

To be able to run the tests manually, define your EDB repositories personal credential `vagrant.yml`. Example in [vagrant.yml-dist](vagrant.yml-dist).

First of all, initialize the virtual machine with `make init`.

* Deploy Use-Case 1 and run the activity script: `make ACTIVITY=true uc1`
* Deploy Use-Case 2 and run the activity script: `make ACTIVITY=true uc2`

To build pgBackRest from sources, use `uc1_full` or `uc2_full` make targets.

To install pgBackRest and **check_pgbackrest** using PGDG packages, without deploying Icinga2, use `uc1_light` or `uc2_light` make targets.

### Change the test profile

Add `PROFILE=xxx` to the make command.

Available profiles: `c7epas`, `c7pg`, `d10epas`, `d10pg`, `u20epas`, `u20pg`.

### Change the pgBackRest repository type

Add `PGBR_REPO_TYPE=xxx` to the make command.

Available types: `azure`, `s3`, `multi`, `posix`.

When setting `multi` repository, both `s3` and `azure` will be used. When setting `posix` repository, the repository path will be automatically adjusted to `/shared/repo1` where */shared* is a shared volume between the docker containers.

### Icinga2

To interact with Icinga2, the easiest way is to use the API:

```bash
# Login to the vagrant box
$ vagrant ssh

# Reschedule check_pgbackrest checks
$ curl -k -s -u 'icinga2-director:anyPassWord' -H 'Accept: application/json' -X POST \
 'https://localhost:5665/v1/actions/reschedule-check' \
 -d '{ "type": "Service", "filter": "match(pattern,service.name)", "filter_vars": { "pattern": "pgbackrest*" }, "pretty": true }' |jq

# Get check_pgbackrest checks status
$ curl -k -s -u 'icinga2-director:anyPassWord' -H 'Accept: application/json' -X GET \
 'https://localhost:5665/v1/objects/services' \
 -d '{ "filter": "match(pattern,service.name)", "filter_vars": { "pattern": "pgbackrest*" } }' |jq
```

### Cleaning

Before changing the `PROFILE` to deploy a new architecture, remove the docker containers and cluster directory using `make PROFILE=xxx clean_ci`.

To remove the vagrant virtual machine: `make clean_vm`.
