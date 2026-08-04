#!/usr/bin/env sh
set -eu
ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$ROOT_DIR"
ENV_FILE=${ENV_FILE:-.env}
if [ ! -f "$ENV_FILE" ]; then
  echo "File $ENV_FILE non trovato." >&2
  exit 1
fi
set -a
. "$ENV_FILE"
set +a
for file in infrastructure/postgres/migrations/*.sql; do
  [ -f "$file" ] || continue
  echo "Applicazione migrazione: $file"
  docker compose exec -T database psql \
    -v ON_ERROR_STOP=1 \
    -U "$DB_USER" -d "$DB_DATABASE" < "$file"
done
echo "Migrazioni completate."
