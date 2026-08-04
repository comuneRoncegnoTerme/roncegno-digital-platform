#!/usr/bin/env sh
set -eu
[ -f .env ] || cp .env.example .env
docker compose up -d
printf '\nContent Hub in avvio: http://localhost:%s\n' "$(grep '^DIRECTUS_PORT=' .env | cut -d= -f2 || echo 8055)"
printf 'Controlla lo stato con: docker compose ps\n'
