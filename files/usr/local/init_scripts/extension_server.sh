#!/bin/bash

# http://go/docs-link/cua-chrome-nexus-extension-release

set -xeuo pipefail

# TODO(epanero): Unify extension server to handle both nexus and agent
# and avoid divergence between prod and research images
HTTP_SERVE_DIR="/usr/local/extensions/nexus/extension_server"


if [ ! -d "${HTTP_SERVE_DIR}" ]; then
  HTTP_SERVE_DIR="/usr/local/extensions"
fi


cd ${HTTP_SERVE_DIR}
ls -lsah

# localhost:31460
python -m http.server 31460
