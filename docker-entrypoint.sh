#!/bin/bash
set -e

# Start Filebeat for sending logs over to logstash
echo "Attempting to start "$($BLACKDUCK_HOME/filebeat/filebeat --version)
$BLACKDUCK_HOME/filebeat/filebeat -c $BLACKDUCK_HOME/filebeat/filebeat.yml start &

# Allow the container to be started with `--user`
if [ "$1" = 'zkServer.sh' -a "$(id -u)" = '0' ]; then
    set -- su-exec zookeeper:root "$0" "$@"
fi

exec "$@"
