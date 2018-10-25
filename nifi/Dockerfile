ARG NIFI_VERSION=1.6.0

FROM apache/nifi:${NIFI_VERSION}
LABEL maintainer="Junhong Liang"

ARG NIFI_VERSION

ARG NAR_DIR="./nars"
ARG CONF_DIR="./conf"
ARG SECRET_DIR="./secrets"

COPY --chown=nifi:nifi ${NAR_DIR}/* /opt/nifi/nifi-${NIFI_VERSION}/lib/
COPY --chown=nifi:nifi ${CONF_DIR}/* /opt/nifi/nifi-${NIFI_VERSION}/conf/
COPY --chown=nifi:nifi ${SECRET_DIR} /opt/secrets

RUN chmod +r /opt/secrets/* && \
    chmod +wr /opt/nifi/nifi-${NIFI_VERSION}/conf/*