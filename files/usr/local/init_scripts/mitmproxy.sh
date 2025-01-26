#!/bin/bash

# http://go/docs-link/cua-chrome-mitmproxy

set -xeuo pipefail

if [ -z "$BASE" ]; then
  echo "missing BASE env var"
  exit 1
fi

if [ -z "$TARGET" ]; then
  echo "missing TARGET env var"
  exit 1
fi

DEBUG="(BASE=${BASE}, TARGET=${TARGET})"

if [[ "${TARGET}" != caas* ]]; then
  echo "🚨 [DISABLED] TARGET is not caas* ${DEBUG}"

  # exit 0 is treated as normal and won't trigger restart
  exit 0
fi

echo "✅ [ENABLED] mitmproxy ${DEBUG}"

CONF_DIR="/home/mitmproxy/.mitmproxy"

RUN_MITMPROXY=(
  mitmdump -q -p 4444
  --set "confdir=${CONF_DIR}"
  -s "${CONF_DIR}/addons.py"
)

# set LOGGING_STYLE below to force json or plain logging
export LOGGING_STYLE="json"

if [ "$LOGGING_STYLE" == "plain" ]; then
  echo "Running without log_forwarder"
  "${RUN_MITMPROXY[@]}"
else
  echo "Running with log_forwarder"
  log_forwarder --service-name mitmproxy -- "${RUN_MITMPROXY[@]}"
fi
