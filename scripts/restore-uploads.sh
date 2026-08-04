#!/usr/bin/env sh
set -eu
[ $# -eq 1 ] || { echo "Uso: $0 backups/uploads/file.tar.gz" >&2; exit 1; }
ARCHIVE=$1
[ -f "$ARCHIVE" ] || { echo "Archivio non trovato: $ARCHIVE" >&2; exit 1; }
ENV_FILE=${ENV_FILE:-.env.production}
COMPOSE="docker compose -f compose.production.yaml --env-file $ENV_FILE"
printf 'ATTENZIONE: gli upload correnti verranno sostituiti. Scrivere RESTORE per continuare: '
read CONFIRM
[ "$CONFIRM" = "RESTORE" ] || exit 1
$COMPOSE exec -T directus sh -c 'rm -rf /directus/uploads/*'
cat "$ARCHIVE" | $COMPOSE exec -T directus tar -C /directus -xzf -
printf 'Upload ripristinati.\n'
