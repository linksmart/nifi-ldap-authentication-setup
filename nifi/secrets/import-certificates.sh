#!/bin/ash

apk --update add openssl

openssl pkcs12 -export -in nifi.cert -inkey nifi.key -out nifi.p12 -password pass:monsoon -name nifi
keytool -importkeystore -srckeystore nifi.p12 -srcstoretype PKCS12 -srcstorepass monsoon -destkeystore keystore.jks -deststorepass monsoon
keytool -export -keystore keystore.jks -alias nifi -file nifi.der -storepass monsoon
# keytool -import -file nifi.der -alias nifi -keystore truststore.jks -storepass monsoon -noprompt
chmod 640 keystore.jks
# chmod 640 truststore.jks

rm -f nifi.der
rm -f nifi.p12
