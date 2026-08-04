#!/usr/bin/env sh
set -eu
PORT=${DIRECTUS_PORT:-8055}
curl -fsS "http://localhost:${PORT}/server/health" && echo
