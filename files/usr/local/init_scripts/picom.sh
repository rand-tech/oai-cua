#!/bin/bash

set -e

if [ -z "$DISPLAY" ]; then
    echo "no DISPLAY env var set"
    exit 1
fi

# this might seem redundant but it's necessary to get picom to work
export DISPLAY="$DISPLAY"
picom --config /dev/null --no-fading-openclose --log-level DEBUG --log-file /tmp/picom.log
