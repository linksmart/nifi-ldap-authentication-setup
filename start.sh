#!/bin/bash

MAVEN_IMAGE=maven:3.5.3-jdk-8-alpine

# Check if keystore exists, if no, create one
if [ ! -f ./nifi/secrets/keystore.jks ]; then
    echo "Generating self signed certificate"
    docker run -it --rm -v "$PWD/nifi/secrets":/usr/src/secrets -w /usr/src/secrets ${MAVEN_IMAGE} /usr/src/secrets/generate-certificates.sh
fi

# Basic variables
DC1=de
DC2=fraunhofer
OU=people
ORGANISATION="Fraunhofer FIT"
DOMAIN="$DC2.$DC1"
BASE_DN="dc=$DC2,dc=$DC1"
OU_DN="ou=$OU,$BASE_DN"
ADMIN_UID=admin
ADMIN_DN="uid=$ADMIN_UID,$OU_DN"

# LDAP Variables
export LDAP_ADMIN_PASSWORD=fit
export LDAP_ORGANISATION=${ORGANISATION}
export LDAP_DOMAIN=${DOMAIN}
# Generate
./utils/print-ldif.sh ${OU} ${OU_DN} ${ADMIN_UID} ${ADMIN_DN} ${LDAP_ADMIN_PASSWORD} > ./ldap/secrets/users.ldif

export NIFI_INITIAL_ADMIN_IDENTITY="$ADMIN_DN"
export NIFI_LDAP_MANAGER_DN="cn=admin,$BASE_DN"
export NIFI_LDAP_MANAGER_PASSWORD=${LDAP_ADMIN_PASSWORD}
export NIFI_LDAP_USER_SEARCH_BASE="$OU_DN"

echo Nifi initial admin identity: ${NIFI_INITIAL_ADMIN_IDENTITY}
echo Nifi LDAP manager: ${NIFI_LDAP_MANAGER_DN}
echo Nifi LDAP search base: ${NIFI_LDAP_USER_SEARCH_BASE}

docker-compose up
