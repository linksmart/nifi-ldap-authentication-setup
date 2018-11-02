# Nifi LDAP Authentication Docker Setup

This repository contains setup configuration for running a secure Nifi docker container which authenticates users using LDAP.

## Quick Start
Run the setup script to generate necessary configurations:
```
./setup.sh -n host-01 -p 8443 --nifi-user admin --nifi-pass fraunhofer -s "CN=host-01,OU=nifi" --new-keystore --new-truststore

    This script generate appropriate configuration and keystore/truststore for a secure Nifi instance.

    USAGE: ./setup.sh [OPTIONS] [ARGUMENTS]

    EXAMPLE: ./setup.sh -n host-01 -p 8443 --nifi-user admin --nifi-pass fraunhofer -s "CN=host-01,OU=nifi" --new-keystore --new-truststore

    OPTIONS:

        -h, --help:               Show the help message.
        -n, --hostname HOSTNAME:  Required. The hostname of machine hosting the Nifi container.
        -p, --port PORT:          Required. The forwarded port to the Nifi UI.
        --nifi-user USERNAME:     Required. The user name to log into Nifi UI.
        --nifi-pass PASSWORD:     Required. The password to log into Nifi UI.
        -d, --domain DOMAIN:      Optional. The domain to be used in LDAP server. This will be turned into the base Distinctive Name, e.g. "example.com" => "dc=example,dc=com" (Default "example.com").
        -O, --organization ORG:   Optional. The organization name used in LDAP server (Default: "Example Inc.").
        --keystore FILE:          Optional. The keystore file to be used in Nifi. If this argument is set, --keypass must also be set.
        --new-keystore:           Optional. Create new keystore. Either this flag or --keystore must be specified.
        --keypass PASSWORD:       Optional. The password to specified keystore or the newly generated one. Must be specified when --keystore is set and must match the password of the specified keystore file. If not specified, a random one will be used.
        --truststore FILE:        Optional. The truststore file to be used in Nifi. If this argument is set, --trustpass must also be set.
        --new-truststore:         Optional. Create new truststore. Either this flag or --truststore must be specified.
        --trustpass PASSWORD:     Optional. The password to the specified truststore or the newly generated one. Must be specified when --truststore is set and must match the password of the specified keystore file. If not specified, a random one will be used.
        --ext-trust:              Optional. Whether to generate a truststore from the keystore, which is intended to be used by another Nifi instance to communicate securely with this one. Only effective when --new-keystore is specified.
        --ext-pass PASSWORD:      Optional. The password to the external truststore. If not specified, a random one is used.
        -s, --server-dn DN:       Optional. The Distinguish Name of the server certificate in keystore (Default: CN=[HOSTNAME],OU=nifi).
        --ldap-provider:          Optional. If this flag is present, the LdapUserGroupProvider will be used, which searches for users having the same base DN as the Nifi admin user.

```

The script will will do the following for you:  
- Generate `keystore.jks` and `truststore.jks` as required;
- Generate a `external-truststore.jks` matching the `keystore.jks` as required, which is intended to be used in another Nifi instance to communicate with this one securely.
- It will generate a `users.ldif` file inside `./ldap/secrets`, which provides the initial Nifi admin identity to the LDAP server;
- It will generate a `.env` file in repository root directory with all properly set environment variables. It will be used by docker-compose.
- If required, it will generate a `authorizers.xml` file under `./nifi/conf`, which contains configuration for using `LdapUserGroupProvider`

After it finishes, you can need to build the images:
```bash
docker-compose -p example_project build --no-cache --force-rm
```

Bring up the stack:
```bash
docker-compose -p example_project  up --detach --force-recreate
```

Now a secure Nifi instance has been started and you can visit it here (the `port` depends on your configuration in the setup script). Log in with the credential you specified in the setup script:
```
https://[hostname]:[port]/nifi
```
Now a secure Nifi instance has been started and you can visit it here (the `port` depends on your configuration in the setup script). Log in with the credential you set in the setup script (`NIFI_ADMIN_UID` and `NIFI_ADMIN_PASSWORD`):

```
https://[hostname]:[port]/nifi
```

After logging in, you'll find most things greyed out. You need to change the policies to grant the current user more access. Since you are using the initial admin account, you have all the permission to add policies or new users.


## Advanced

#### Putting Files into Nifi
1. If you have NAR files to add to the Nifi library, simply put them into `./nifi/nars`, they'll be copied into the newly built image in build time.  

2. If you have configurations files to add to the Nifi instance, simply put them into `./nifi/conf`. Typically, you can put in the following files:
    - `flow.xml.gz`: this file contains the current processor setup on the Nifi canvas
    - `./templates/*.xml`: template files   

## Notes
Here is something I learned, which is not clearly documented in official documents:  

1. On bootstrap, the LDAP container automatically turns `LDAP_DOMAIN` into a base DN. For example, if `LDAP_DOMAIN` is `fraunhofer.de`, it will become the base DN `dc=fraunhofer,dc=de`.  

2. A default LDAP admin account with a common name of `admin` is automatically added on top of this base DN, e.g. `cn=admin,dc=fraunhofer,dc=de`. The environment variable `LDAP_ADMIN_PASSWORD` is the password for this admin account.

3. Nifi should use this LDAP admin account to bind to the LDAP server. You can specify this by setting the three environment variables:
    - `LDAP_AUTHENTICATION_STRATEGY`: use `Simple` 
    - `LDAP_MANAGER_DN`: the DN of the default admin, e.g. `cn=admin,dc=fraunhofer,dc=de`
    - `LDAP_MANAGER_PASSWORD`: the password for this admin, which must be the same as `LDAP_ADMIN_PASSWORD` above. 

    It is important to distinguish this account from the Nifi admin account mentioned below. This account is only used to access LDAP server for user credential retrieval. The Nifi admin account is used to access the Nifi instance.

3. The file `ldap/secrets/users.ldif` specifies the Nifi admin account, e.g. `uid=admin,ou=people,dc=fraunhofer,dc=de`. This DN needs to be added to Nifi as the initial admin identity by setting the environment variable `INITIAL_ADMIN_IDENTITY` to this DN for the Nifi container.
