#!/usr/bin/env sh
set -eu
[ $# -eq 1 ] || { echo "Uso: $0 backups/database/file.dump" >&2; exit 1; }
DUMP=$1
[ -f "$DUMP" ] || { echo "Backup non trovato: $DUMP" >&2; exit 1; }
ENV_FILE=${ENV_FILE:-.env.production}
set -a
. "./$ENV_FILE"
set +a
COMPOSE="docker compose -f compose.production.yaml --env-file $ENV_FILE"
printf 'ATTENZIONE: il database %s verrà sovrascritto. Scrivere RESTORE per continuare: ' "$DB_DATABASE"
read CONFIRM
[ "$CONFIRM" = "RESTORE" ] || exit 1
$COMPOSE exec -T database dropdb -U "$DB_USER" --if-exists "$DB_DATABASE"
$COMPOSE exec -T database createdb -U "$DB_USER" "$DB_DATABASE"
cat "$DUMP" | $COMPOSE exec -T database pg_restore -U "$DB_USER" -d "$DB_DATABASE" --clean --if-exists --no-owner
printf 'Ripristino completato.\n'
