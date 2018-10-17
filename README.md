# Nifi LDAP Authentication Setup

This repository contains setup configuration for running a secure Nifi instance which authenticates users using LDAP. (TODO: more description)

## Quick Start
Build the Nifi image:
```
./nifi/build.sh
```

Build the LDAP image:
```
./nifi/build.sh
```

Run docker-compose:
```
docker-compose up
```

## Notes
1. TODO: Do not understand why they need to substitute the default `start.sh` with a custom `start.sh` in Nifi. Need to test.
2. The LDAP container is given environment variables `LDAP_ADMIN_PASSWORD` and `LDAP_DOMAIN` on start-up. 
The `LDAP_DOMAIN` is typically a domain name, e.g. `fraunhofer.de`. This domain name will be parsed and turned into the base DN, e.g. `dc=fraunhofer,dc=de`.
An LDAP admin account with a common name of `admin` is automatically added on top of this base DN, e.g. `cn=admin,dc=fraunhofer,dc=de`. The environment variable `LDAP_ADMIN_PASSWORD` is the password for this admin account.
As a result, this credential should be used by Nifi, if it uses a `Simple` binding to connect to the LDAP server (see the environment variables `LDAP_AUTHENTICATION_STRATEGY`, `LDAP_MANAGER_DN` and `LDAP_MANAGER_PASSWORD` of the Nifi container). 
It is important to distinguish this account from the Nifi admin account mentioned below.
3. The file `ldap/secrets/users.ldif` specifies the Nifi admin account, e.g. `uid=admin,ou=people,dc=fraunhofer,dc=de`. This DN needs to be added to Nifi as the initial admin identity by setting the environment variable `INITIAL_ADMIN_IDENTITY` to this DN for the Nifi container.
