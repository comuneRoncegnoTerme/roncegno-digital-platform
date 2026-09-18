#!/usr/bin/env sh
set -eu
ENV_FILE=${ENV_FILE:-.env.staging}
PROJECT_NAME=${COMPOSE_PROJECT_NAME:-roncegno-staging}
docker compose -p "$PROJECT_NAME" -f compose.staging.yaml --env-file "$ENV_FILE" ps
