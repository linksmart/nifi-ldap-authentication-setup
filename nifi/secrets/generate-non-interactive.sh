#!/bin/ash -e

SERVER_DNAME=$1
KEYSTORE_PSWD=$2
TRUSTSTORE_PSWD=$3
GENERATE_EXT_TRUSTSTORE=$4
EXT_TRUSTSTORE_PSWD=$5

echo "--------- Processing keystore/truststore ---------"

if [ ! -f ./secrets/keystore.jks ]; then
    echo "keystore.jks does not exist. Generating new keystore."
    echo "*** Generating keystore with certificate \"${SERVER_DNAME}\" ***"
    keytool -genkey -keyalg RSA -alias nifi -keystore keystore.jks -keypass "${KEYSTORE_PSWD}" -storepass "${KEYSTORE_PSWD}" -validity 365 -keysize 4096 -dname "${SERVER_DNAME}"
    chmod 640 keystore.jks
    echo "*** Keystore generated ***"

    # Generate a truststore for this keystore, so that it could be easily used on other Nifi instances to communicate with this Nifi instance securely
    rm -f nifi.der
    rm -f external_truststore.jks
    keytool -export -keystore keystore.jks -alias nifi -file nifi.der -storepass "${KEYSTORE_PSWD}"

    if [ "${GENERATE_EXT_TRUSTSTORE}" == "YES" ]; then
        echo "*** Generating EXTERNAL truststore ***"
        keytool -import -file nifi.der -alias nifi -keystore external_truststore.jks -storepass "${EXT_TRUSTSTORE_PSWD}" -noprompt
        chmod 640 external_truststore.jks
        echo "*** Dummy truststore generated ***"
    fi

    # If no truststore.jks detected, generate a dummy one
    if [ ! -f ./secrets/truststore.jks ]; then
        echo "*** Generating dummy truststore ***"
        keytool -import -file nifi.der -alias nifi -keystore truststore.jks -storepass "${TRUSTSTORE_PSWD}" -noprompt
        chmod 640 truststore.jks
        echo "*** Dummy truststore generated ***"
    fi

    # Clean up
    rm -f nifi.der
    echo "*** Keystore generation finished! ***"
fi

# When keystore.jks exists, but no truststore.jks exists
if [ ! -f ./truststore.jks ]; then
    # Try to extract the first certificate from keystore, and add it to truststore
    ALIAS_LINE=$(keytool -v -list -keystore keystore.jks | grep 'Alias name:' | head -n 1)
    ALIAS=${ALIAS_LINE:12}
    keytool -export -keystore keystore.jks -alias nifi -file nifi.der -storepass "${KEYSTORE_PSWD}"
    keytool -import -file nifi.der -alias nifi -keystore truststore.jks -storepass "${TRUSTSTORE_PSWD}" -noprompt
    rm -f nifi.der
    chmod 640 truststore.jks
fi

echo "--------- Processing finished ---------"



