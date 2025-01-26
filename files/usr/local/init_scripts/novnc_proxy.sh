#!/bin/bash

set -e

exec /opt/novnc/utils/novnc_proxy --vnc localhost:${VNC_PORT} --listen ${NOVNC_PROXY_PORT}
