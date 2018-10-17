FROM apache/nifi:1.6.0
LABEL maintainer="Monsoon consortium"

ARG NAR_VERSION=0.1 

COPY --chown=nifi:nifi ./sh/start.sh /opt/nifi/scripts
COPY --chown=nifi:nifi ./src/nifi-monsoon-nar/target/nifi-monsoon-nar-${NAR_VERSION}.nar /opt/nifi/nifi-1.6.0/lib

USER root
