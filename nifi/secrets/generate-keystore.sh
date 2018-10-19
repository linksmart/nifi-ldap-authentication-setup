#!/bin/ash

DNAME=$1
PSWD=$2
GEN_TRUSTSTORE=$3

echo "Generating new keystore and truststore with DN: $DNAME"

keytool -genkey -keyalg RSA -alias nifi -keystore keystore.jks -keypass "$PSWD" -storepass "$PSWD" -validity 365 -keysize 4096 -dname "$DNAME"
chmod 640 keystore.jks

if [ ! -z ${GEN_TRUSTSTORE} -a ${GEN_TRUSTSTORE} -eq "true" ]; then
    keytool -export -keystore keystore.jks -alias nifi -file nifi.der -storepass "$PSWD"
    keytool -import -file nifi.der -alias nifi -keystore truststore.jks -storepass "$PSWD" -noprompt
    rm -f nifi.der
    chmod 640 truststore.jks
fi



