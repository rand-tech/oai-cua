#!/bin/bash

set -e

if [ -z "$DISPLAY" ]; then
    echo "no DISPLAY env var set"
    exit 1
fi

if [ -z "$DISPLAY_RESOLUTION" ]; then
    echo "no DISPLAY_RESOLUTION env var set"
    exit 1
fi

exec Xvfb "$DISPLAY" -screen 0 $DISPLAY_RESOLUTION
