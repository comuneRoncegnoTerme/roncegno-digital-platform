#!/usr/bin/env sh
set -eu
ENV_FILE=${ENV_FILE:-.env.production}
[ -f "$ENV_FILE" ] || { echo "File $ENV_FILE non trovato" >&2; exit 1; }
docker compose -f compose.production.yaml --env-file "$ENV_FILE" pull
docker compose -f compose.production.yaml --env-file "$ENV_FILE" up -d --remove-orphans
