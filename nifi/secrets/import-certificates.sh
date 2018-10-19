#!/bin/ash

KEY_FILE=$1
CERT_FILE=$2
PSWD=$3
GEN_TRUSTSTORE=$4

apk --update add openssl

openssl pkcs12 -export -in ${CERT_FILE} -inkey ${KEY_FILE} -out nifi.p12 -password pass:${PSWD} -name nifi
keytool -importkeystore -srckeystore nifi.p12 -srcstoretype PKCS12 -srcstorepass ${PSWD} -destkeystore keystore.jks -deststorepass ${PSWD}
keytool -export -keystore keystore.jks -alias nifi -file nifi.der -storepass ${PSWD}
chmod 640 keystore.jks

if [ ! -z ${GEN_TRUSTSTORE} -a ${GEN_TRUSTSTORE} -eq "true" ]; then
    keytool -import -file nifi.der -alias nifi -keystore truststore.jks -storepass ${PSWD} -noprompt
    chmod 640 truststore.jks
fi

rm -f nifi.der
rm -f nifi.p12
