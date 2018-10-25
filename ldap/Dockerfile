ARG LDAP_VERSION=latest

FROM osixia/openldap:${LDAP_VERSION}
LABEL maintainer="Junhong Liang"

ARG SECRET_DIR="./secrets"

ADD ${SECRET_DIR}/*.ldif /container/service/slapd/assets/config/bootstrap/ldif/custom/

