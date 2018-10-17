FROM apache/nifi:1.6.0
LABEL maintainer="Monsoon consortium"

COPY --chown=nifi:nifi ./sh/start.sh /opt/nifi/scripts
COPY --chown=nifi:nifi ./sh/nars/*.nar /opt/nifi/nifi-1.6.0/lib/
COPY --chown=nifi:nifi ./conf/* /opt/nifi/nifi-1.7.1/conf/
COPY --chown=nifi:nifi ./secrets /opt/secrets

USER root
