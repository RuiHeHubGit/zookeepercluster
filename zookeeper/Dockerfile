ARG BASE_IMAGE="hub.c.163.com/library/tomcat:latest"
ARG BASE_PATH="/opt/dev"

FROM $BASE_IMAGE

#Env Variables
ENV ZOOKEEPER_BASE="$BASE_PATH/zookeeper" \
    ZK_DATA_DIR="/tmp/zookeeper"

RUN mkdir $ZOOKEEPER_BASE $-p

ADD zookeeper-3.4.9.tar.gz $ZOOKEEPER_BASE

WORKDIR $ZOOKEEPER_BASE

USER dev

USER root

COPY supervisord.conf /etc/supervisor/supervisord.conf

COPY zookeeper_supervisor.ini /etc/supervisor/supervisor.d/zookeeper_supervisor.ini

COPY zookeeper.sh ./bin

RUN touch /var/log/zookeeper_supervisord.log && \
mkdir $ZK_DATA_DIR -p && \
chown -R dev:dev $ZOOKEEPER_BASE $ZK_DATA_DIR ./bin/zookeeper.sh /usr/bin/supervisord \
/tmp/supervisor.sock /tmp/supervisord.log /tmp/supervisord.pid /var/log/zookeeper_supervisord.log && \
echo "dev ALL=(ALL) NOPASSWD: /bin/cp, /bin/sed, /usr/bin/touch" >> /etc/sudoers

EXPOSE 2181

USER dev

ENTRYPOINT ["/usr/bin/supervisord"]
