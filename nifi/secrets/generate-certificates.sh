#!/bin/bash

DNS="monsoon.ekf.tuke.sk"
DNAME="CN=$DNS,OU=monsoon,O=Technical University of Kosice,L=Kosice,ST=Slovakia,C=SK"
keytool -genkey -keyalg RSA -alias nifi -keystore keystore.jks -keypass monsoon -storepass monsoon -validity 365 -keysize 4096 -dname "$DNAME"
keytool -export -keystore keystore.jks -alias nifi -file nifi.der -storepass monsoon
keytool -import -file nifi.der -alias nifi -keystore truststore.jks -storepass monsoon -noprompt
rm -f nifi.der
chmod 640 keystore.jks
chmod 640 truststore.jks
