#!/usr/bin/env sh
set -eu
ENV_FILE=${ENV_FILE:-.env.staging}
PROJECT_NAME=${COMPOSE_PROJECT_NAME:-roncegno-staging}
[ -f "$ENV_FILE" ] || { echo "File $ENV_FILE non trovato" >&2; exit 1; }
docker compose -p "$PROJECT_NAME" -f compose.staging.yaml --env-file "$ENV_FILE" pull
docker compose -p "$PROJECT_NAME" -f compose.staging.yaml --env-file "$ENV_FILE" up -d --remove-orphans
