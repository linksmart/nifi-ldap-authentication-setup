# Nifi LDAP Authentication Setup

This repository contains setup configuration for running a secure Nifi instance which authenticates users using LDAP.

## Quick Start
Before getting started, you may want to set this script, as well as all scripts inside `utils/` to executable first:
```
chmod 755 ./start.sh
chmod 755 ./utils/*.sh
```

Run the starting script. You can configure some parameters inside this script:
```bash
./start.sh
```

Now a secure Nifi instance has been started and you can visit it here (the port could be different depending on your configuration in the starting script). Log in with the credential you set in the starting script (`NIFI_ADMIN_UID` and `NIFI_ADMIN_PASSWORD`):
```
https://localhost:5443
```

After logging in, you'll find most things greyed out. You need to change the policies to grant the current user more access. Since you are using the initial admin account, you have all the permission to add policies or new users.


## Advanced
1. If you have NAR files to add to the Nifi library, simply put them into `./nifi/nars`, they'll be copied into the newly built image in start-up.
2. If you have configurations files to add to the Nifi instance, simply put them into `./nifi/conf`. Typically, you can put in the following files:
    - `flow.xml.gz`: this file contains the current processor setup on the Nifi canvas
    - `./templates/*.xml`: template files 
3. This repository also comes with some scripts to help you set up your keystore and truststore. To generate a new keystore with self-signed certificate and trust that certificate, run this command:
    ```bash
    docker run -it --rm -v "$PWD/nifi/secrets":/usr/src/secrets \
        -w /usr/src/secrets openjdk:8-alpine \
        /usr/src/secrets/generate-certificates.sh \
        [DN of certificate] [store password]
    ```
    where `DN of certificate` typically has the following form:
    ```
    CN=fit.fraunhofer.de,OU=people,O=Fraunhofer FIT,L=Sankt Augustin,ST=Nordrhein Westfalen,C=DE
    ```
    `store password` is the password to both stores.
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
