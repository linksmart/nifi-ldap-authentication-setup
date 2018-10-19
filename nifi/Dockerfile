FROM apache/nifi:1.6.0
LABEL maintainer="Junhong Liang"

COPY --chown=nifi:nifi ./nars/* /opt/nifi/nifi-1.6.0/lib/
COPY --chown=nifi:nifi ./conf/* /opt/nifi/nifi-1.6.0/conf/
COPY --chown=nifi:nifi ./secrets /opt/secrets

RUN chmod +r /opt/secrets/* && \
    chmod +wr /opt/nifi/nifi-1.6.0/conf/*