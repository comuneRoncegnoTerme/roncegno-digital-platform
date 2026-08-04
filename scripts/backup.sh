#!/usr/bin/env sh
set -eu
ENV_FILE=${ENV_FILE:-.env.production}
[ -f "$ENV_FILE" ] || { echo "File $ENV_FILE non trovato" >&2; exit 1; }
set -a
. "./$ENV_FILE"
set +a
STAMP=$(date -u +%Y%m%dT%H%M%SZ)
DB_DIR=${BACKUP_DB_DIR:-./backups/database}
UPLOAD_DIR=${BACKUP_UPLOAD_DIR:-./backups/uploads}
RETENTION=${BACKUP_RETENTION_DAYS:-14}
mkdir -p "$DB_DIR" "$UPLOAD_DIR"
COMPOSE="docker compose -f compose.production.yaml --env-file $ENV_FILE"
$COMPOSE exec -T database pg_dump -U "$DB_USER" -d "$DB_DATABASE" -Fc > "$DB_DIR/roncegno-hub-$STAMP.dump"
$COMPOSE exec -T directus tar -C /directus -czf - uploads > "$UPLOAD_DIR/roncegno-uploads-$STAMP.tar.gz"
find "$DB_DIR" -type f -name '*.dump' -mtime "+$RETENTION" -delete
find "$UPLOAD_DIR" -type f -name '*.tar.gz' -mtime "+$RETENTION" -delete
printf 'Backup completato: %s\n' "$STAMP"
