#!/bin/bash -e

echo " ---------------------"
echo "|                     |"
echo "|  Nifi - LDAP stack  |"
echo "|                     |"
echo " ---------------------"

# Function to generate random password
gen_pass(){
    echo $(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)
}

# Remove old generated files
rm -f ./ldap/secrets/users.ldif
rm -f ./.env

read -p "Enter the domain, e.g. \"example.com\":" DOMAIN
read -p "Enter the organization name, e.g. \"Example Inc.\":" ORGANISATION
OU=system
# DN calculation
IFS='.' read -r -a DC_ARRAY <<< "${DOMAIN}"
for DC in "${DC_ARRAY[@]}"; do
   if [ ! -z $BASE_DN ]; then
       BASE_DN="${BASE_DN},"
   fi
   BASE_DN="${BASE_DN}dc=${DC}"
done
OU_DN="ou=$OU,$BASE_DN"

read -p "The hostname of the machine running Nifi container:" NIFI_HOST
read -p "The host's forwarded port to the Nifi UI:" NIFI_PORT

read -p "The username of the initial admin, e.g. \"nifi-admin\":" NIFI_ADMIN_UID
echo "The password of the initial admin:"
read -s NIFI_ADMIN_PASSWORD

echo "The password of the default LDAP manager \"cn=admin,${BASE_DN}\" (press enter to let the script generate a random password):"
read -s LDAP_ADMIN_PASSWORD
if [ -z ${LDAP_ADMIN_PASSWORD} ]; then
    echo "No password provided, generating a random password"
    LDAP_ADMIN_PASSWORD=$(gen_pass)
fi

echo "The namespace to be used for building docker images and containers (press enter to use default namespace \"secure\"):"
read -s DOCKER_NAMESPACE
if [ -z ${DOCKER_NAMESPACE} ]; then
    DOCKER_NAMESPACE=secure
fi

# Nifi env variables
NIFI_ADMIN_DN="uid=$NIFI_ADMIN_UID,$OU_DN"
NIFI_INITIAL_ADMIN_IDENTITY="$NIFI_ADMIN_DN"
NIFI_LDAP_MANAGER_DN="cn=admin,$BASE_DN"
NIFI_LDAP_MANAGER_PASSWORD=${LDAP_ADMIN_PASSWORD}
NIFI_LDAP_USER_SEARCH_BASE="$OU_DN"

# LDAP env variables
LDAP_ORGANISATION=${ORGANISATION}
LDAP_DOMAIN=${DOMAIN}

if [ -f ./nifi/secrets/keystore.jks ]; then
    echo -n "keystore.jks detected. Please provide the password for the the keystore: "
    read -s NIFI_KEYSTORE_PASS
    echo " "
else
    NIFI_KEYSTORE_PASS=$(gen_pass)
fi

if [ -f ./nifi/secrets/truststore.jks ]; then
    echo -n "truststore.jks detected. Please provide the password for the the truststore: "
    read -s NIFI_TRUSTSTORE_PASS
    echo " "
else
    NIFI_TRUSTSTORE_PASS=$(gen_pass)
fi

# Run the script to generate keystore/truststore, if they don't exist
docker run -it --rm -v "$PWD/nifi/secrets":/usr/src/secrets \
        -w /usr/src/secrets --user ${UID} openjdk:8-alpine \
        /usr/src/secrets/generate.sh \
        "${NIFI_KEYSTORE_PASS}" "${NIFI_TRUSTSTORE_PASS}"



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

echo "To run the stack, first you need to build the image:"
echo " "
echo "   docker-compose -p example_project build --no-cache --force-rm"
echo " "
echo "Bring up the stack:"
echo " "
echo "   docker-compose -p example_project up -d --force-recreate"
echo " "
echo "If everything goes well, you can visit Nifi under this URL:"
echo " "
echo "   https://${NIFI_HOST}:${NIFI_PORT}"
echo " "
echo "Log in with the username /"${NIFI_ADMIN_UID}/" and the password you set earlier."
echo " "
echo "Happy flowing!"
echo " "
echo " "