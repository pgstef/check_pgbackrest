# Validation process

First of all, initialize the virtual machine:

```bash
time make init
```

## PostgreSQL

```bash
# Use case 1 - Rocky 8 - pgBackRest packages, multi-repositories
time make ACTIVITY=true PROFILE=ro8pg PGBR_REPO_TYPE=multi uc1
make PROFILE=ro8pg clean_ci

# Use case 2 - Rocky 8 - pgBackRest packages
time make ACTIVITY=true PROFILE=ro8pg uc2
make PROFILE=ro8pg clean_ci

# Use case 1 - Ubuntu 20.04 - pgBackRest packages
time make ACTIVITY=true PROFILE=u20pg uc1
make PROFILE=u20pg clean_ci

# Use case 2 - Ubuntu 20.04 - pgBackRest packages, multi-repositories
time make ACTIVITY=true PROFILE=u20pg PGBR_REPO_TYPE=multi uc2
make PROFILE=u20pg clean_ci
```

* To build pgBackRest from sources, use `uc1_full` of `uc2_full` make target

## EDB Postgres Advanced Server

```bash
# Use case 1 - Rocky 8 - pgBackRest packages, multi-repositories
time make ACTIVITY=true PROFILE=ro8epas PGBR_REPO_TYPE=multi uc1
make PROFILE=c7epas clean_ci

# Use case 2 - Rocky 8 - pgBackRest packages
time make ACTIVITY=true PROFILE=ro8epas uc2
make PROFILE=c7epas clean_ci

# Use case 1 - Ubuntu 20.04 - pgBackRest packages
time make ACTIVITY=true PROFILE=u20epas uc1
make PROFILE=u20epas clean_ci

# Use case 2 - Ubuntu 20.04 - pgBackRest packages, multi-repositories
time make ACTIVITY=true PROFILE=u20epas PGBR_REPO_TYPE=multi uc2
make PROFILE=u20epas clean_ci
```

* To build pgBackRest from sources, use `uc1_full` of `uc2_full` make target
