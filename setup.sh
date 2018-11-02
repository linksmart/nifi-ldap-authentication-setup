#!/bin/bash -e

cat << EOF
     -------------------------------
    |                               |
    |       Nifi - LDAP Stack       |
    |                               |
     -------------------------------
EOF

while [[ $# -gt 0 ]]; do
key="$1"
    case $key in
        -h|--help)
        HELP=YES
        break
        ;;
        -n|--hostname)
        NIFI_HOST="$2"
        shift # past argument
        shift # past value
        ;;
        -p|--port)
        NIFI_PORT="$2"
        shift # past argument
        shift # past value
        ;;
        --nifi-user)
        NIFI_ADMIN_UID="$2"
        shift # past argument
        shift # past value
        ;;
        --nifi-pass)
        NIFI_ADMIN_PASS="$2"
        shift # past argument
        shift # past value
        ;;
        -d|--domain)
        DOMAIN="$2"
        shift # past argument
        shift # past value
        ;;
        -O|--organization)
        ORGANIZATION="$2"
        shift # past argument
        shift # past value
        ;;
        --ldap-pass)
        LDAP_ADMIN_PASS="$2"
        shift # past argument
        shift # past value
        ;;
        --keystore)
        KEYSTORE="$2"
        shift # past argument
        shift # past value
        ;;
        --new-keystore)
        NEW_KEYSTORE=YES
        shift # past argument
        ;;
        --key-pass)
        KEYSTORE_PASS="$2"
        shift # past argument
        shift # past value
        ;;
        --truststore)
        TRUSTSTORE="$2"
        shift # past argument
        shift # past value
        ;;
        --new-truststore)
        NEW_TRUSTSTORE=YES
        shift # past argument
        ;;
        --trust-pass)
        TRUSTSTORE_PASS="$2"
        shift # past argument
        shift # past value
        ;;
        --ext-trust)
        GENERATE_EXT_TRUSTSTORE=YES
        shift # past argument
        ;;
        --ext-pass)
        EXT_TRUSTSTORE_PASS="$2"
        shift # past argument
        shift # past value
        ;;
        -s|--server-dn)
        SERVER_DN="$2"
        shift # past argument
        shift # past value
        ;;
        --ldap-provider)
        USE_LDAP_PROVIDER=YES
        shift # past argument
        ;;
        *)    # unknown option
        UNKNOWN_FLAG="$1"
        break
        ;;
    esac
done

print_help(){

    cat << EOF

    This script generate appropriate configuration and keystore/truststore for a secure Nifi instance.

    USAGE: ./setup.sh [OPTIONS] [ARGUMENTS]

    EXAMPLE: ./setup.sh -n host-01 -p 8443 --nifi-user admin --nifi-pass fraunhofer -s "CN=host-01,OU=nifi" --new-keystore --new-truststore

    OPTIONS:

EOF
    cat << EOF | column -s"|" -t
        -h, --help:|Show the help message.
        -n, --hostname HOSTNAME:|Required. The hostname of machine hosting the Nifi container.
        -p, --port PORT:|Required. The forwarded port to the Nifi UI.
        --nifi-user USERNAME:|Required. The user name to log into Nifi UI.
        --nifi-pass PASSWORD:|Required. The password to log into Nifi UI.
        -d, --domain DOMAIN:|Optional. The domain to be used in LDAP server. This will be turned into the base Distinctive Name, e.g. "example.com" => "dc=example,dc=com" (Default "example.com").
        -O, --organization ORG:|Optional. The organization name used in LDAP server (Default: "Example Inc.").
        --keystore FILE:|Optional. The keystore file to be used in Nifi. If this argument is set, --keypass must also be set.
        --new-keystore:|Optional. Create new keystore. Either this flag or --keystore must be specified.
        --keypass PASSWORD:|Optional. The password to specified keystore or the newly generated one. Must be specified when --keystore is set and must match the password of the specified keystore file. If not specified, a random one will be used.
        --truststore FILE:|Optional. The truststore file to be used in Nifi. If this argument is set, --trustpass must also be set.
        --new-truststore:|Optional. Create new truststore. Either this flag or --truststore must be specified.
        --trustpass PASSWORD:|Optional. The password to the specified truststore or the newly generated one. Must be specified when --truststore is set and must match the password of the specified keystore file. If not specified, a random one will be used.
        --ext-trust:|Optional. Whether to generate a truststore from the keystore, which is intended to be used by another Nifi instance to communicate securely with this one.
        --ext-pass PASSWORD:|Optional. The password to the external truststore. If not specified, a random one is used.
        -s, --server-dn DN:|Optional. The Distinguish Name of the server certificate in keystore (Default: CN=[HOSTNAME],OU=nifi).
        --ldap-provider:|Optional. If this flag is present, the LdapUserGroupProvider will be used, which searches for users having the same base DN as the Nifi admin user.
EOF

}

gen_pass(){
    echo $(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)
}

gen_file(){
    TEMPLATE="$(cat $1)"
    TEMPLATE=$(sed 's/\([^\\]\)"/\1\\"/g; s/^"/\\"/g' <<< "$TEMPLATE")
    eval "echo \"${TEMPLATE}\" > $2"
}

# Check the correctness of arguments
if [ ! -z "${HELP}" ]; then
    print_help
    exit 0
fi
if [ ! -z "${UNKNOWN_FLAG}" ]; then
    echo "[ERROR] Unknown flag ${UNKOWN_FLAG} "
    print_help
    exit 1
fi
if [ -z "${NIFI_HOST}" ]; then
    echo "[ERROR] \"-n | --hostname\" is not specified "
    print_help
    exit 1
fi
if [ -z "${NIFI_PORT}" ]; then
    echo "[ERROR] \"-p | --port\" is not specified "
    print_help
    exit 1
fi
if [ -z "${NIFI_ADMIN_UID}" ]; then
    echo "[ERROR] \"--nifi-user\" is not specified "
    print_help
    exit 1
fi
if [ -z "${NIFI_ADMIN_PASS}" ]; then
    echo "[ERROR] \"--nifi-pass\" is not specified "
    print_help
    exit 1
fi
if [ ! -z "${KEYSTORE}" -a -z "${KEYSTORE_PASS}" ]; then
    echo "[ERROR] keystore specified but no keystore pass is given"
    print_help
    exit 1
fi
if [ ! -z "${TRUSTSTORE}" -a -z "${TRUSTSTORE_PASS}" ]; then
    echo "[ERROR] truststore specified but no truststore pass is given"
    print_help
    exit 1
fi
if [ -z "${KEYSTORE}" -a -z "${NEW_KEYSTORE}" ]; then
    echo "[ERROR] Either --keystore or --new-keystore must be specified"
    print_help
    exit 1
fi
if [ -z "${TRUSTSTORE}" -a -z "${NEW_TRUSTSTORE}" ]; then
    echo "[ERROR] Either --truststore or --new-truststore must be specified"
    print_help
    exit 1
fi
if [ ! -z "${KEYSTORE}" -a ! -f "${KEYSTORE}" ]; then
    echo "[ERROR] ${KEYSTORE} does not exist."
    exit 1
fi
if [ ! -z "${TRUSTSTORE}" -a ! -f "${TRUSTSTORE}" ]; then
    echo "[ERROR] ${TRUSTSTORE} does not exist."
    exit 1
fi

# If both --keystore and --new-keystore is specified, ignore --new-keystore
if [ ! -z "${KEYSTORE}" -a ! -z "${NEW_KEYSTORE}" ]; then
    unset NEW_KEYSTORE
fi
if [ ! -z "${TRUSTSTORE}" -a ! -z "${NEW_TRUSTSTORE}" ]; then
    unset NEW_TRUSTSTORE
fi

# Prepare files
if [ ! -z "${NEW_KEYSTORE}" ]; then
    rm -f ./nifi/secrets/keystore.jks
fi
if [ ! -z "${NEW_TRUSTSTORE}" ]; then
    rm -f ./nifi/secrets/truststore.jks
fi
if [ ! -z "${KEYSTORE}" ]; then
    mv -f "${KEYSTORE}" ./nifi/secrets/keystore.jks
fi
if [ ! -z "${TRUSTSTORE}" ]; then
    mv -f "${TRUSTSTORE}" ./nifi/secrets/truststore.jks
fi

# Remove old generated files
rm -f ./ldap/secrets/users.ldif
rm -f ./.env
rm -f ./nifi/conf/authorizers.xml

# Give default values
: ${CLIENT_DN:="CN=user, OU=nifi"}
: ${SERVER_DN:="CN=${NIFI_HOST},OU=nifi"}
: ${DOMAIN:="example.com"}
: ${ORGANIZATION:="Example Inc."}
: ${LDAP_ADMIN_PASS:=$(gen_pass)}
: ${KEYSTORE_PASS:=$(gen_pass)}
: ${TRUSTSTORE_PASS:=$(gen_pass)}
: ${GENERATE_EXT_TRUSTSTORE:=NO}
: ${EXT_TRUSTSTORE_PASS:=$(gen_pass)}

# DN calculation
IFS='.' read -r -a DC_ARRAY <<< "${DOMAIN}"
for DC in "${DC_ARRAY[@]}"; do
   if [ ! -z "${BASE_DN}" ]; then
       BASE_DN="${BASE_DN},"
   fi
   BASE_DN="${BASE_DN}dc=${DC}"
done
OU=system
OU_DN="ou=$OU,$BASE_DN"

NIFI_ADMIN_DN="uid=$NIFI_ADMIN_UID,$OU_DN"
NIFI_INITIAL_ADMIN_IDENTITY="$NIFI_ADMIN_DN"
NIFI_LDAP_MANAGER_DN="cn=admin,$BASE_DN"
NIFI_LDAP_MANAGER_PASSWORD=${LDAP_ADMIN_PASS}
NIFI_LDAP_USER_SEARCH_BASE="$OU_DN"

# Generate keystore/truststore
docker run -it --rm -v "$PWD/nifi/secrets":/usr/src/secrets \
        -w /usr/src/secrets --user ${UID} openjdk:8-alpine \
        /usr/src/secrets/generate.sh \
        "${SERVER_DN}" "${KEYSTORE_PASS}" \
        "${TRUSTSTORE_PASS}" \
        "${GENERATE_EXT_TRUSTSTORE}" "${EXT_TRUSTSTORE_PASS}"

# Generate bootstrap ldif file, which contains the initial Nifi admin credential
# This file will be read in by the OpenLDAP server during start up, creating a single user entry in the LDAP database
gen_file "./templates/users.ldif" "./ldap/secrets/users.ldif"

# Generate .env file for docker-compose
gen_file "./templates/.env" "./.env"

# Generate authorizers.xml, if necessary
if [ ! -z ${USE_LDAP_PROVIDER} ]; then
    gen_file "./templates/authorizers.xml" "./nifi/conf/authorizers.xml"
fi

cat << EOF
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
            Setup is done!
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
To run the stack, first build the image:

   docker-compose -p example_project build --no-cache --force-rm

Bring up the stack:

   docker-compose -p example_project up -d --force-recreate

If everything goes well, you can visit Nifi under this URL:

   https://${NIFI_HOST}:${NIFI_PORT}

Log in with the username "${NIFI_ADMIN_UID}" and the password you set earlier.

Happy flowing!


EOF