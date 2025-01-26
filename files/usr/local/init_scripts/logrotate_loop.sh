#!/bin/sh

set -e

# rotate every 24 hrs
ROTATE_EVERY_SEC=86400

echo "running logrotate loop. rotating logs every ${ROTATE_EVERY_SEC} seconds"
while true; do
    logrotate -v /etc/logrotate.d/supervisord
    sleep ${ROTATE_EVERY_SEC}
done
