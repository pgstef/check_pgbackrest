# Validation process

First of all, initialize the virtual machine:

```bash
time make init
```

## PostgreSQL

```bash
# Use case 1 - CentOS 7 - pgBackRest packages, multi-repositories
make ACTIVITY=true PROFILE=c7pg PGBR_REPO_TYPE=multi uc1
make PROFILE=c7pg clean-ci

# Use case 2 - CentOS 7 - pgBackRest packages, multi-repositories
make ACTIVITY=true PROFILE=c7pg PGBR_REPO_TYPE=multi uc2
make PROFILE=c7pg clean-ci

# Use case 1 - Ubuntu 20.04 - pgBackRest packages, multi-repositories
make ACTIVITY=true PROFILE=u20pg PGBR_REPO_TYPE=multi uc1
make PROFILE=u20pg clean-ci

# Use case 2 - Ubuntu 20.04 - pgBackRest packages, multi-repositories
make ACTIVITY=true PROFILE=u20pg PGBR_REPO_TYPE=multi uc2
make PROFILE=u20pg clean-ci
```

* To build pgBackRest from sources, use `uc1_full` of `uc2_full` make target

## EDB Postgres Advanced Server

```bash
# Use case 1 - CentOS 7 - pgBackRest packages, multi-repositories
make ACTIVITY=true PROFILE=c7epas PGBR_REPO_TYPE=multi uc1
make PROFILE=c7epas clean-ci

# Use case 2 - CentOS 7 - pgBackRest packages, multi-repositories
make ACTIVITY=true PROFILE=c7epas PGBR_REPO_TYPE=multi uc2
make PROFILE=c7epas clean-ci

# Use case 1 - Ubuntu 20.04 - pgBackRest packages, multi-repositories
make ACTIVITY=true PROFILE=u20epas PGBR_REPO_TYPE=multi uc1
make PROFILE=u20epas clean-ci

# Use case 2 - Ubuntu 20.04 - pgBackRest packages, multi-repositories
make ACTIVITY=true PROFILE=u20epas PGBR_REPO_TYPE=multi uc2
make PROFILE=u20epas clean-ci
```

* To build pgBackRest from sources, use `uc1_full` of `uc2_full` make target