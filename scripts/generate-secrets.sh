#!/usr/bin/env sh
set -eu
command -v openssl >/dev/null 2>&1 || { echo "openssl non disponibile" >&2; exit 1; }
printf 'DIRECTUS_KEY=%s\n' "$(openssl rand -hex 32)"
printf 'DIRECTUS_SECRET=%s\n' "$(openssl rand -hex 64)"
printf 'DB_PASSWORD=%s\n' "$(openssl rand -base64 36 | tr -d '\n')"
printf 'REDIS_PASSWORD=%s\n' "$(openssl rand -base64 36 | tr -d '\n')"
printf 'ADMIN_PASSWORD=%s\n' "$(openssl rand -base64 28 | tr -d '\n')"
