#!/bin/ash -e

KEYSTORE_PSWD=$1
TRUSTSTORE_PSWD=$2

# When keystore.jks does not exist
if [ ! -f ./secrets/keystore.jks ]; then
    echo "keystore.jks does not exist. Generating new keystore."
    read -p "Please enter the subject of cert. It typically has the form \"CN=[hostname],OU=nifi\":" SERVER_CERT_SUBJECT
    echo "---------------------------------------------"
    echo "Generating keystore with certificate: ${SERVER_CERT_SUBJECT}"
    echo "---------------------------------------------"
    keytool -genkey -keyalg RSA -alias nifi -keystore keystore.jks -keypass "${KEYSTORE_PSWD}" -storepass "${KEYSTORE_PSWD}" -validity 365 -keysize 4096 -dname "${SERVER_CERT_SUBJECT}"

    # Generate a truststore for this keystore, so that it could be easily used on other Nifi instances to communicate with this Nifi instance securely
    rm -f external.der
    rm -f external_truststore.jks

    keytool -export -keystore keystore.jks -alias nifi -file external.der -storepass "${KEYSTORE_PSWD}"

    # If no truststore.jks detected, generate a dummy one
    if [ ! -f ./secrets/truststore.jks ]; then
        keytool -import -file external.der -alias nifi -keystore truststore.jks -storepass "${TRUSTSTORE_PSWD}" -noprompt
    fi

    echo -n "Generating a truststore for EXTERNAL usage from this keystore. Please provide password for this truststore: "
    read -s EXTERNAL_TRUSTSTORE_PSWD
    echo " "
    keytool -import -file external.der -alias nifi -keystore external_truststore.jks -storepass "${EXTERNAL_TRUSTSTORE_PSWD}" -noprompt

    # Clean up
    rm -f external.der
    chmod 640 keystore.jks
    chmod 640 external_truststore.jks
    echo "---------------------------------------------"
    echo "Keystore generation finished!"
    echo "---------------------------------------------"
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

