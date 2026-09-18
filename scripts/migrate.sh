#!/usr/bin/env sh
set -eu
ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$ROOT_DIR"

ENV_FILE=${ENV_FILE:-.env}
COMPOSE_FILE=${COMPOSE_FILE:-docker-compose.yml}
PROJECT_NAME=${COMPOSE_PROJECT_NAME:-}

if [ ! -f "$ENV_FILE" ]; then
  echo "File $ENV_FILE non trovato." >&2
  exit 1
fi

if [ ! -f "$COMPOSE_FILE" ]; then
  echo "File Compose $COMPOSE_FILE non trovato." >&2
  exit 1
fi

set -a
. "$ENV_FILE"
set +a

compose_exec() {
  if [ -n "$PROJECT_NAME" ]; then
    docker compose -p "$PROJECT_NAME" -f "$COMPOSE_FILE" --env-file "$ENV_FILE" exec -T database "$@"
  else
    docker compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" exec -T database "$@"
  fi
}

for file in infrastructure/postgres/migrations/*.sql; do
  [ -f "$file" ] || continue
  echo "Applicazione migrazione: $file"
  compose_exec psql -v ON_ERROR_STOP=1 -U "$DB_USER" -d "$DB_DATABASE" < "$file"
done

echo "Migrazioni completate."
