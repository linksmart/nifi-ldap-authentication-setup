FROM apache/nifi:1.6.0
LABEL maintainer="Monsoon consortium"

COPY --chown=nifi:nifi ./sh/start.sh /opt/nifi/scripts
COPY --chown=nifi:nifi ./nars/*.nar /opt/nifi/nifi-1.6.0/lib
COPY --chown=nifi:nifi ./secrets /opt/secrets
COPY --chown=nifi:nifi ./conf /opt/nifi/nifi-1.6.0/conf

USER root
