#!/bin/sh
# Creates .env from .env.sample, ready to start: every password, key and token drawn at random,
# the users of the shared services named, and mail sent to localhost until you set your server.
# Run it with `docker compose -f init.yml run --rm init`: nothing to install but Docker.
set -eu
if [ -e .env ]; then echo ".env already exists: delete it first to create a new one." >&2; exit 1; fi

hex() { head -c 24 /dev/urandom | od -An -tx1 | tr -d ' \n'; }
b64() { head -c 32 /dev/urandom | base64; }
uuid() { cat /proc/sys/kernel/random/uuid; }

umask 077
tr -d '\r' < .env.sample | while IFS= read -r line || [ -n "$line" ]; do
  case "$line" in [A-Z]*=*) ;; *) printf '%s\n' "$line"; continue ;; esac
  key=${line%%=*}
  case "$key" in
    POSTGRES_USER|RABBITMQ_DEFAULT_USER) value=xtm ;;
    SMTP_HOST) value=localhost ;;
    SMTP_PORT) value=25 ;;
    SMTP_AUTH|SMTP_SSL_ENABLE) value=false ;;
    SMTP_USERNAME|SMTP_PASSWORD|IMAP_HOST|IMAP_USERNAME|IMAP_PASSWORD) printf '%s=\n' "$key"; continue ;;
    OPENCTI_ENCRYPTION_KEY) value=$(b64) ;;
    *_ADMIN_TOKEN|*HEALTHCHECK*) value=$(uuid) ;;
    *PASSWORD*|*_PASS|*SECRET*|*SALT*|*REGISTRATION_TOKEN|*ENCRYPTION_KEY) value=$(hex) ;;
    *) printf '%s\n' "$line"; continue ;;
  esac
  printf '%s=%s\n' "$key" "$value"
done > .env

# Readable by you alone, and yours, not root's, when the container runs as root on Linux.
chmod 600 .env
chown "$(stat -c %u:%g .env.sample)" .env 2>/dev/null || true

get() { sed -n "s/^$1=//p" .env; }
cat <<MSG
.env created, with its secrets. Start the stack with:

  docker compose up -d --pull always

Then sign in, once every service is healthy (a few minutes the first time), as $(get OPENCTI_ADMIN_EMAIL):
  XTM One   http://localhost:$(get XTM_ONE_PORT)   password $(get XTM_ONE_ADMIN_PASSWORD)
  OpenCTI   http://localhost:$(get OPENCTI_PORT)   password $(get OPENCTI_ADMIN_PASSWORD)
  OpenAEV   http://localhost:$(get OPENAEV_PORT)   password $(get OPENAEV_ADMIN_PASSWORD)
  OpenCRQ   http://localhost:$(get OPENCRQ_PORT)   create its owner account on the first visit
Every password, key and token stays in .env.
MSG
