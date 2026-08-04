#!/usr/bin/env sh
set -eu
ENV_FILE=${ENV_FILE:-.env.production}
BRANCH=${DEPLOY_BRANCH:-main}
./scripts/backup.sh
git fetch origin "$BRANCH"
git checkout "$BRANCH"
git pull --ff-only origin "$BRANCH"
./scripts/production-up.sh
./scripts/production-healthcheck.sh
printf 'Deploy completato.\n'
