#!/bin/ash -e

KEY_PSWD=$1
TRUST_PSWD=$2

echo "Generating dummy truststore"
keytool -export -keystore keystore.jks -alias nifi -file nifi.der -storepass "$KEY_PSWD"
keytool -import -file nifi.der -alias nifi -keystore truststore.jks -storepass "$TRUST_PSWD" -noprompt
rm -f nifi.der
chmod 640 truststore.jks




