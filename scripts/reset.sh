#!/usr/bin/env sh
set -eu
printf 'Questa operazione elimina database e upload locali. Continuare? [y/N] '
read answer
[ "$answer" = "y" ] || [ "$answer" = "Y" ] || exit 0
docker compose down -v
rm -rf directus/uploads/*
touch directus/uploads/.gitkeep
docker compose up -d
