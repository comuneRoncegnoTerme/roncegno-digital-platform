#!/usr/bin/env sh
set -eu
ENV_FILE=${ENV_FILE:-.env.production}
docker compose -f compose.production.yaml --env-file "$ENV_FILE" down
