#!/bin/ash -e

DNAME=$1
KEY_PSWD=$2
TRUST_PSWD=$3
GEN_TRUSTSTORE=$4

echo "Generating new keystore with DN: $DNAME"

keytool -genkey -keyalg RSA -alias nifi -keystore keystore.jks -keypass "$KEY_PSWD" -storepass "$KEY_PSWD" -validity 365 -keysize 4096 -dname "$DNAME"
chmod 640 keystore.jks

if [ ! -z ${GEN_TRUSTSTORE} -a "${GEN_TRUSTSTORE}" = "true" ]; then
    echo "Generating new truststore"
    keytool -export -keystore keystore.jks -alias nifi -file nifi.der -storepass "$KEY_PSWD"
    keytool -import -file nifi.der -alias nifi -keystore truststore.jks -storepass "$TRUST_PSWD" -noprompt
    rm -f nifi.der
    chmod 640 truststore.jks
fi



