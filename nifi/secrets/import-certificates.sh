#!/bin/ash

KEY_FILE=$1
CERT_FILE=$2
PSWD=$3

apk --update add openssl

openssl pkcs12 -export -in ${CERT_FILE} -inkey ${KEY_FILE} -out nifi.p12 -password "pass:${PSWD}" -name nifi
keytool -importkeystore -srckeystore nifi.p12 -srcstoretype PKCS12 -srcstorepass "${PSWD}" -destkeystore keystore.jks -deststorepass "${PSWD}"
chmod 640 keystore.jks

rm -f nifi.p12
