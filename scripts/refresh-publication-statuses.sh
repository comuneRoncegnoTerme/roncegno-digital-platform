#!/usr/bin/env sh
set -eu
ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$ROOT_DIR"
ENV_FILE=${ENV_FILE:-.env}
set -a
. "$ENV_FILE"
set +a
docker compose exec -T database psql -U "$DB_USER" -d "$DB_DATABASE" \
  -v ON_ERROR_STOP=1 -c 'SELECT hub_refresh_publication_statuses();'
