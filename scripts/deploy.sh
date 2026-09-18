#!/usr/bin/env sh
set -eu
ENV_FILE=${ENV_FILE:-.env.production}
BRANCH=main
sh ./scripts/backup.sh
git fetch origin "$BRANCH"
git checkout "$BRANCH"
git pull --ff-only origin "$BRANCH"
ENV_FILE="$ENV_FILE" sh ./scripts/production-up.sh
ENV_FILE="$ENV_FILE" sh ./scripts/production-healthcheck.sh
printf 'Deploy produzione completato da branch %s.\n' "$BRANCH"
