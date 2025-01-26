#!/bin/bash

set -xeuo pipefail

if [ -z "$TARGET" ]; then
  echo "missing TARGET env var"
  exit 1
fi

if [[ "$TARGET" != caas-next-cua-bing-at-home* ]]; then
  echo "🚨 [DISABLED] TARGET is not caas-next-cua-bing-at-home (${TARGET})"

  # exit 0 is treated as normal and won't trigger restart
  exit 0
fi

echo "✅ [ENABLED] cua_bing_at_home (${TARGET})"

PORT=9002 python -m cua_bing_at_home.app
