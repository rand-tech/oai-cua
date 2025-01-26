#!/bin/bash

set -e

if [ -z "$DISPLAY" ]; then
    echo "no DISPLAY env var set"
    exit 1
fi

exec x11vnc -rfbport $VNC_PORT -display "$DISPLAY" -forever -nopw -shared
