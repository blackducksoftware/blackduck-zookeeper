FROM zookeeper:3.4.11

ARG VERSION
ARG LASTCOMMIT
ARG BUILDTIME
ARG BUILD

LABEL com.blackducksoftware.hub.vendor="Black Duck Software, Inc." \
      com.blackducksoftware.hub.version="$VERSION" \
      com.blackducksoftware.hub.lastCommit="$LASTCOMMIT" \
      com.blackducksoftware.hub.buildTime="$BUILDTIME" \
      com.blackducksoftware.hub.build="$BUILD"

ENV BLACKDUCK_RELEASE_INFO "com.blackducksoftware.hub.vendor=Black Duck Software, Inc. \
com.blackducksoftware.hub.version=$VERSION \
com.blackducksoftware.hub.lastCommit=$LASTCOMMIT \
com.blackducksoftware.hub.buildTime=$BUILDTIME \
com.blackducksoftware.hub.build=$BUILD"

RUN echo -e "$BLACKDUCK_RELEASE_INFO" > /etc/blackduckrelease

ENV BLACKDUCK_HOME=/opt/blackduck/zookeeper \
	BLACKDUCK_DATA_DIR="$BLACKDUCK_HOME/data"

COPY docker-entrypoint.sh "$BLACKDUCK_HOME/bin/"
COPY zoo.cfg "$BLACKDUCK_HOME/conf/"

RUN set -e \
	&& mkdir -p "$BLACKDUCK_HOME/conf" "$BLACKDUCK_HOME/data" "$BLACKDUCK_HOME/datalog" \
	&& chown -R zookeeper:root "$BLACKDUCK_HOME/conf" "$BLACKDUCK_HOME/data" "$BLACKDUCK_HOME/datalog" \
	&& chmod -R a+rwx "$BLACKDUCK_HOME/conf" "$BLACKDUCK_HOME/data" "$BLACKDUCK_HOME/datalog" \
    && rm /usr/bin/nc

# Filebeat - Installation and Configuration #
ENV FILEBEAT_VERSION 5.5.2
ENV ZOO_LOG4J_PROP='INFO,CONSOLE,ROLLINGFILE'
ENV ZOO_LOG_DIR="$BLACKDUCK_HOME/logs"

RUN apk add --no-cache --virtual .hub-rundeps \
    tar \
    gzip \
    curl

RUN curl -L https://artifacts.elastic.co/downloads/beats/filebeat/filebeat-$FILEBEAT_VERSION-linux-x86_64.tar.gz | \
	tar xz -C $BLACKDUCK_HOME
RUN mv $BLACKDUCK_HOME/filebeat-$FILEBEAT_VERSION-linux-x86_64 $BLACKDUCK_HOME/filebeat \
    && chown -R zookeeper:root $BLACKDUCK_HOME/filebeat
COPY filebeat.yml "$BLACKDUCK_HOME/filebeat/filebeat.yml"
COPY log4j.properties "/conf/log4j.properties"
RUN mkdir "$BLACKDUCK_HOME/logs"
RUN touch "$BLACKDUCK_HOME/logs/zookeeper.log"
RUN chmod 666 "$BLACKDUCK_HOME/logs/zookeeper.log"
RUN	chmod -R og+rwx "$BLACKDUCK_HOME/filebeat" \
	&& chmod 644 "$BLACKDUCK_HOME/filebeat/filebeat.yml"

VOLUME [ "$BLACKDUCK_HOME/data", "$BLACKDUCK_HOME/datalog", "$BLACKDUCK_HOME/conf" ]
ENV PATH=$PATH:/$BLACKDUCK_HOME/bin
WORKDIR /opt/blackduck/zookeeper
ENTRYPOINT [ "docker-entrypoint.sh" ]
CMD [ "zkServer.sh", "start-foreground", "/opt/blackduck/zookeeper/conf/zoo.cfg" ]
