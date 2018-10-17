FROM osixia/openldap:latest
LABEL maintainer="Monsoon consortium"

ADD sh/docker-healthcheck.sh /usr/local/bin/
ADD secrets/*.ldif /container/service/slapd/assets/config/bootstrap/ldif/custom/

HEALTHCHECK CMD ["docker-healthcheck.sh"]
