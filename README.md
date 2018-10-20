# Nifi LDAP Authentication Setup

This repository contains setup configuration for running a secure Nifi instance which authenticates users using LDAP.

## Quick Start
Run the setup script to generate necessary configurations:
```bash
./setup.sh
```

The script will will do the following for you:  
- If no `keystore.jks` exists inside `./nifi/secrets`, it will prompt you to generate one with self-signed certificate;
- If no `truststore.jks` exists inside `./nifi/secrets`, it will prompt you to generate a dummy truststore;
- It will generate a `users.ldif` file inside `./ldap/secrets`, which provides the initial Nifi admin identity to the LDAP server;
- It will generate a `.env` file in repository root directory with all properly set environment variables. It will be used by docker-compose.
 
After it finishes, you can run the following to bring up the stack:
```bash
docker-compose up
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
    
#### Security
1. You can provide your own keystore and truststore. Just name them `keystore.jks` and `truststore.jks` respectively and put them into `./nifi/screts`. Then follow the quick start instruction.

2. If you already have a private key and a certificate (or a chain of certificates), put them in `./nifi/secrets`, run the following command:
    ```bash
    docker run -it --rm -v "$PWD/nifi/secrets":/usr/src/secrets \
        -w /usr/src/secrets --user ${UID} openjdk:8-alpine \
        /usr/src/secrets/import-certificates.sh \
        [key file name] [cert file name] [store password]
    ```
    This will generate the `keystore.jks` from your certificate and private key.
## Notes
Here is something I learned, which is not clearly documented in official documents:  

1. On bootstrap, the LDAP container automatically turns `LDAP_DOMAIN` into a base DN. For example, if `LDAP_DOMAIN` is `fraunhofer.de`, it will become the base DN `dc=fraunhofer,dc=de`.  

2. A default LDAP admin account with a common name of `admin` is automatically added on top of this base DN, e.g. `cn=admin,dc=fraunhofer,dc=de`. The environment variable `LDAP_ADMIN_PASSWORD` is the password for this admin account.

3. Nifi should use this LDAP admin account to bind to the LDAP server. You can specify this by setting the three environment variables:
    - `LDAP_AUTHENTICATION_STRATEGY`: use `Simple` 
    - `LDAP_MANAGER_DN`: the DN of the default admin, e.g. `cn=admin,dc=fraunhofer,dc=de`
    - `LDAP_MANAGER_PASSWORD`: the password for this admin, which must be the same as `LDAP_ADMIN_PASSWORD` above. 

    It is important to distinguish this account from the Nifi admin account mentioned below.  This account is only used to access LDAP server for user credential retrieval. The Nifi admin account is used to access the Nifi instance.

3. The file `ldap/secrets/users.ldif` specifies the Nifi admin account, e.g. `uid=admin,ou=people,dc=fraunhofer,dc=de`. This DN needs to be added to Nifi as the initial admin identity by setting the environment variable `INITIAL_ADMIN_IDENTITY` to this DN for the Nifi container.
