#!/bin/bash

set -xe

echo "🔐 Adding trusted certificates…"
# ensure the certs DB and password file do not exist before re-building
#
# we have found that when we run the container on CaaS, the certs DB already
# exists, so the following lines ensure that we build the certs DB from scratch
NSSDB_DIR="/home/oai/.pki/nssdb"
NSSDB_PASSWORD_FILE="/home/oai/.nssdbp"
su-exec oai rm -rf "$NSSDB_DIR"
su-exec oai rm -rf "$NSSDB_PASSWORD_FILE"
su-exec oai mkdir -p "$NSSDB_DIR"
su-exec oai echo "nssdbpwd1" > "$NSSDB_PASSWORD_FILE"

# next, set up the password file and the actual database. do some work here
# to ensure that, if chrome gets restarted inside the container (i.e. the
# container itself is still running but chrome is restarted), that this
# script is idempotent with respect to the password file/db


if [ -z "$(ls -A $NSSDB_DIR)" ]; then
    echo "NSS database directory is empty. Initializing…"
    su-exec oai certutil -d "$NSSDB_DIR" -N -f "$NSSDB_PASSWORD_FILE"
else
    echo "NSS database already initialized."
fi

# this section adds all the certificates that exist in the directory
for cert_file in "/usr/local/share/ca-certificates"/*.crt; do
    echo "Adding certificate [${cert_file}] to NSS database…"
    cert_name=$(basename "$cert_file" .crt)
    su-exec oai certutil -d "$NSSDB_DIR" -A -f "$NSSDB_PASSWORD_FILE" -t "C,," -n "OpenAI-${cert_name}" -i "$cert_file"
done
