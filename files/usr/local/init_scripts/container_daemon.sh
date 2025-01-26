#!/bin/bash

set -e

if [ -z "$DISPLAY" ]; then
    echo "missing DISPLAY env var"
    exit 1
fi
if [ -z "$CDP_PORT" ]; then
    echo "missing CDP_PORT env var"
    exit 1
fi

# make sure this location is the place to which the log forwarder and container
# daemon were copied in the dockerfile
log_forwarder --service-name container_daemon -- container_daemon
