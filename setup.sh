#!/bin/bash -e

#-------------------------------------------
# Basic configuration for the LDAP root DN
#-------------------------------------------
DOMAIN_COMPONENTS=("fit" "fraunhofer" "de")
OU=people
ORGANISATION="Fraunhofer FIT"
# This variable will be used to construct part of the image name and container name,
# e.g. ${DOCKER_NAMESPACE}/nifi as image name, and ${DOCKER_NAMESPACE}-nifi as container name
DOCKER_NAMESPACE="fit"

#-------------------------------------------
# LDAP Variables
# This password is the password for default LDAP admin, which has a DN of "cn=admin,dc=<user specified>,dc=<user specified>"
#-------------------------------------------
LDAP_ADMIN_PASSWORD=fit

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Do not modify the lines below!
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

echo "==========================="
echo "Starting Nifi - LDAP stack"
echo "==========================="

# Function to generate random password
gen_pass(){
    echo $(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)
}

# Remove old generated files
rm -f ./ldap/secrets/users.ldif
rm -f ./.env

# String split??
IFS=', ' read -r -a array <<< "$string"

read -p "The hostname of the machine running Nifi container:\n" NIFI_HOST
read -p "The host's forwarded port to the Nifi UI:\n" NIFI_PORT

read -p "The username of the initial admin, e.g. \"nifi-admin\":\n" NIFI_ADMIN_UID
echo "The password of the initial admin:"
read -s NIFI_ADMIN_PASSWORD

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

if [ ! -f ./secrets/keystore.jks ]; then
    echo "keystore.jks does not exist. Generating a new keystore."
    read -p "Please enter the subject of cert. It typically has the form \"CN=[hostname],OU=nifi\":" SERVER_CERT_SUBJECT
    NIFI_KEYSTORE_PASS=gen_pass
    echo " "
    echo "---------------------------------------------"
    echo "Generating certificate with subject field: ${SERVER_CERT_SUBJECT}"
    echo "---------------------------------------------"
    docker run -it --rm -v "$PWD/secrets":/usr/src/secrets \
        -w /usr/src/secrets --user ${UID} openjdk:8-alpine \
        /usr/src/secrets/generate-keystore.sh \
        "${SERVER_CERT_SUBJECT}" "${NIFI_KEYSTORE_PASS}"
    echo "---------------------------------------------"
    echo "Keystore generation finished!"
    echo "---------------------------------------------"
else
    echo -n "keystore.jks detected. Please provide the password for the the keystore: "
    read -s NIFI_KEYSTORE_PASS
fi

if [ ! -f ./secrets/truststore.jks ]; then
    echo "truststore.jks does not exist. Generating new truststore.jks"
    NIFI_TRUSTSTORE_PASS=gen_pass
    docker run -it --rm -v "$PWD/secrets":/usr/src/secrets \
        -w /usr/src/secrets --user ${UID} openjdk:8-alpine \
        /usr/src/secrets/generate-truststore.sh \
        "${NIFI_KEYSTORE_PASS}" "${NIFI_TRUSTSTORE_PASS}"
    echo "---------------------------------------------"
    echo "Truststore generation finished!"
    echo "---------------------------------------------"
else
    echo -n "truststore.jks detected. Please provide the password for the the truststore: "
    read -s NIFI_TRUSTSTORE_PASS
fi


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
DOCKER_NAMESPACE=${DOCKER_NAMESPACE}

NIFI_INITIAL_ADMIN_IDENTITY=${NIFI_INITIAL_ADMIN_IDENTITY}
NIFI_LDAP_MANAGER_DN=${NIFI_LDAP_MANAGER_DN}
NIFI_LDAP_MANAGER_PASSWORD=${NIFI_LDAP_MANAGER_PASSWORD}
NIFI_LDAP_USER_SEARCH_BASE=${NIFI_LDAP_USER_SEARCH_BASE}
NIFI_KEYSTORE_PASS=${NIFI_KEYSTORE_PASS}
NIFI_TRUSTSTORE_PASS=${NIFI_TRUSTSTORE_PASS}
NIFI_HOST=${NIFI_HOST}
NIFI_PORT=${NIFI_PORT}

LDAP_ADMIN_PASSWORD=${LDAP_ADMIN_PASSWORD}
LDAP_ORGANISATION=${LDAP_ORGANISATION}
LDAP_DOMAIN=${LDAP_DOMAIN}
EOF

echo Nifi initial admin identity: ${NIFI_INITIAL_ADMIN_IDENTITY}
echo Nifi LDAP manager: ${NIFI_LDAP_MANAGER_DN}
echo Nifi LDAP search base: ${NIFI_LDAP_USER_SEARCH_BASE}

echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
echo "Setup finished!"
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"

echo "To start the stack, simply run:"
echo " "
echo "  docker-compose up"
echo " "
echo "Then you can visit Nifi under this URL:"
echo " "
echo "  https://${NIFI_HOST}:${NIFI_PORT}"
echo " "
echo "Happy flowing!"
echo " "
echo " "