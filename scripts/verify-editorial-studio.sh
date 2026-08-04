#!/usr/bin/env sh
set -eu
ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$ROOT_DIR"
ENV_FILE=${ENV_FILE:-.env}
set -a
. "$ENV_FILE"
set +a
echo "== Migrazioni =="
docker compose exec -T database psql -U "$DB_USER" -d "$DB_DATABASE" -c 'TABLE hub_schema_migrations;'
echo "== Dashboard =="
docker compose exec -T database psql -U "$DB_USER" -d "$DB_DATABASE" -c 'TABLE hub_editorial_dashboard;'
echo "== Prossimi eventi =="
docker compose exec -T database psql -U "$DB_USER" -d "$DB_DATABASE" -c 'SELECT title,start_datetime,place_name FROM hub_upcoming_events ORDER BY start_datetime LIMIT 10;'
