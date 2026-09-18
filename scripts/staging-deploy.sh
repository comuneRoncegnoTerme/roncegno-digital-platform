#!/usr/bin/env sh
set -eu
BRANCH=develop
git fetch origin "$BRANCH"
git checkout "$BRANCH"
git pull --ff-only origin "$BRANCH"
ENV_FILE=${ENV_FILE:-.env.staging} ./scripts/staging-up.sh
ENV_FILE=${ENV_FILE:-.env.staging} ./scripts/staging-healthcheck.sh
printf 'Deploy staging completato da branch %s.\n' "$BRANCH"
