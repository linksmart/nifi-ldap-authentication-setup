#!/bin/bash

ldapsearch -A -x -D "cn=admin,dc=monsoon,dc=eu" -w "${LDAP_ADMIN_PASSWORD}" -H ldap://ldap:389 -b "dc=monsoon,dc=eu" > /dev/null && exit 0 || exit 1
