#!/bin/bash


OU=$1
OU_DN=$2
ADMIN_UID=$3
ADMIN_DN=$4
PSWD=$5

#define the template.
cat  << EOF
version: 1

# entry for a people container
dn: ${OU_DN}
objectclass:top
objectclass:organizationalUnit
ou: ${OU}

# entry for admin
dn: ${ADMIN_DN}
objectclass:top
objectclass:person
objectclass:organizationalPerson
objectclass:inetOrgPerson
cn: ${ADMIN_UID}
sn: ${ADMIN_UID}
uid: ${ADMIN_UID}
userPassword:${PSWD}

EOF