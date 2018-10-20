#!/bin/ash -e

DNAME=$1
KEY_PSWD=$2

echo "Generating new keystore with DN: $DNAME"

keytool -genkey -keyalg RSA -alias "$DNAME" -keystore keystore.jks -keypass "$KEY_PSWD" -storepass "$KEY_PSWD" -validity 365 -keysize 4096 -dname "$DNAME"
chmod 640 keystore.jks



