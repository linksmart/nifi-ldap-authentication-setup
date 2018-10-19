#!/bin/bash

#-------------------------------------------
# Basic configuration for the LDAP root DN
#-------------------------------------------
DOMAIN_COMPONENTS=("fit" "fraunhofer" "de")
OU=people
ORGANISATION="Fraunhofer FIT"

#-------------------------------------------
# The hostname of the container host machine and the forwarded port to Nifi web interface
# These parameters allows a secure Nifi to accept HTTP request sent to ${NIFI_HOST}:${NIFI_PORT}, useful when Nifi is running behind a proxy or in a container.
#-------------------------------------------
NIFI_HOST=ucc-ipc-0
NIFI_PORT=5443

#-------------------------------------------
# Nifi admin credential
# You'll be using this credential to log into Nifi as initial admin user
#-------------------------------------------
NIFI_ADMIN_UID=admin
NIFI_ADMIN_PASSWORD=fit

#-------------------------------------------
# Nifi keystore/truststore password
# The password to the keystore.jks and truststore.jks
#-------------------------------------------
NIFI_STORE_PASS=monsoon

#-------------------------------------------
# LDAP Variables
# This password is the password for default LDAP admin, which has a DN of "cn=admin,dc=<user specified>,dc=<user specified>"
#-------------------------------------------
LDAP_ADMIN_PASSWORD=fit

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Do not modify the lines below!
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# Basic DN calculation
for DC in "${DOMAIN_COMPONENTS[@]}"; do
   if [ ! -z $DOMAIN ]; then
       DOMAIN="${DOMAIN}."
       BASE_DN="${BASE_DN},"
   fi
   DOMAIN="${DOMAIN}${DC}"
   BASE_DN="${BASE_DN}dc=${DC}"
done
OU_DN="ou=$OU,$BASE_DN"

# Nifi env variables
NIFI_ADMIN_DN="uid=$NIFI_ADMIN_UID,$OU_DN"
NIFI_INITIAL_ADMIN_IDENTITY="$NIFI_ADMIN_DN"
NIFI_LDAP_MANAGER_DN="cn=admin,$BASE_DN"
NIFI_LDAP_MANAGER_PASSWORD=${LDAP_ADMIN_PASSWORD}
NIFI_LDAP_USER_SEARCH_BASE="$OU_DN"

# LDAP env variables
LDAP_ORGANISATION=${ORGANISATION}
LDAP_DOMAIN=${DOMAIN}

echo Nifi initial admin identity: ${NIFI_INITIAL_ADMIN_IDENTITY}
echo Nifi LDAP manager: ${NIFI_LDAP_MANAGER_DN}
echo Nifi LDAP search base: ${NIFI_LDAP_USER_SEARCH_BASE}

# Generate bootstrap ldif file, which contains the initial Nifi admin credential
# This file will be read in by the OpenLDAP server during start up, creating a single user entry in the LDAP database
cat  << EOF > ./ldap/secrets/users.ldif
version: 1

# entry for a people container
dn: ${OU_DN}
objectclass:top
objectclass:organizationalUnit
ou: ${OU}

# entry for admin
dn: ${NIFI_ADMIN_DN}
objectclass:top
objectclass:person
objectclass:organizationalPerson
objectclass:inetOrgPerson
cn: ${NIFI_ADMIN_UID}
sn: ${NIFI_ADMIN_UID}
uid: ${NIFI_ADMIN_UID}
userPassword:${NIFI_ADMIN_PASSWORD}

EOF

# Generate .env file for docker-compose
cat  << EOF > ./.env
DOMAIN=${DOMAIN}

NIFI_INITIAL_ADMIN_IDENTITY=${NIFI_INITIAL_ADMIN_IDENTITY}
NIFI_LDAP_MANAGER_DN=${NIFI_LDAP_MANAGER_DN}
NIFI_LDAP_MANAGER_PASSWORD=${NIFI_LDAP_MANAGER_PASSWORD}
NIFI_LDAP_USER_SEARCH_BASE=${NIFI_LDAP_USER_SEARCH_BASE}
NIFI_STORE_PASS=${NIFI_STORE_PASS}
NIFI_HOST=${NIFI_HOST}
NIFI_PORT=${NIFI_PORT}

LDAP_ADMIN_PASSWORD=${LDAP_ADMIN_PASSWORD}
LDAP_ORGANISATION=${LDAP_ORGANISATION}
LDAP_DOMAIN=${LDAP_DOMAIN}
EOF

