#!/usr/bin/env sh
set -eu
BRANCH=develop
ENV_FILE=${ENV_FILE:-.env.staging}

git fetch origin "$BRANCH"
git checkout "$BRANCH"
git pull --ff-only origin "$BRANCH"

ENV_FILE="$ENV_FILE" sh ./scripts/staging-up.sh
ENV_FILE="$ENV_FILE" sh ./scripts/staging-healthcheck.sh
printf 'Deploy staging completato da branch %s.\n' "$BRANCH"
