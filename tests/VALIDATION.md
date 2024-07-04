# Validation process

First of all, initialize the virtual machine:

```bash
time make init
```

## PostgreSQL

```bash
# Directly-attached shared storage - Rocky 8 - pgBackRest packages, multi-repositories
time make ACTIVITY=true PROFILE=ro8pg PGBR_REPO_TYPE=multi uc1
make PROFILE=ro8pg clean_ci

# Dedicated repository host - Rocky 8 - pgBackRest packages
time make ACTIVITY=true PROFILE=ro8pg uc2
make PROFILE=ro8pg clean_ci

# Directly-attached shared storage - Rocky 9 - pgBackRest packages
time make ACTIVITY=true PROFILE=ro9pg uc1
make PROFILE=ro9pg clean_ci

# Dedicated repository host - Rocky 9 - pgBackRest packages, multi-repositories
time make ACTIVITY=true PROFILE=ro9pg PGBR_REPO_TYPE=multi uc2
make PROFILE=ro9pg clean_ci

# Directly-attached shared storage - Debian 11 - pgBackRest packages, multi-repositories
time make ACTIVITY=true PROFILE=d11pg PGBR_REPO_TYPE=multi uc1
make PROFILE=d11pg clean_ci

# Dedicated repository host - Debian 11 - pgBackRest packages
time make ACTIVITY=true PROFILE=d11pg uc2
make PROFILE=d11pg clean_ci

# Directly-attached shared storage - Ubuntu 22.04 - pgBackRest packages
time make ACTIVITY=true PROFILE=u22pg uc1
make PROFILE=u22pg clean_ci

# Dedicated repository host - Ubuntu 22.04 - pgBackRest packages, multi-repositories
time make ACTIVITY=true PROFILE=u22pg PGBR_REPO_TYPE=multi uc2
make PROFILE=u22pg clean_ci
```

* To build pgBackRest from sources, use `uc1_full` of `uc2_full` make target
