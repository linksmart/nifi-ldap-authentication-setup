#!/bin/ash -e

KEY_PSWD=$1
TRUST_PSWD=$2

echo "Generating dummy truststore"
ALIAS_LINE=$(keytool -v -list -keystore keystore.jks -storepass ${KEY_PSWD} | grep 'Alias name:' | head -n 1)
ALIAS=${ALIAS_LINE:12}
keytool -export -keystore keystore.jks -alias "${ALIAS}" -file nifi.der -storepass "$KEY_PSWD"
keytool -import -file nifi.der -alias nifi -keystore truststore.jks -storepass "$TRUST_PSWD" -noprompt
rm -f nifi.der
chmod 640 truststore.jks




