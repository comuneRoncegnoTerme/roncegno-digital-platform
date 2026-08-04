#!/usr/bin/env sh
set -eu
mkdir -p directus/snapshots
STAMP=$(date +%Y%m%d-%H%M%S)
docker compose exec directus npx directus schema snapshot "/directus/snapshots/schema-${STAMP}.yaml"
echo "Snapshot creato in directus/snapshots/schema-${STAMP}.yaml"
