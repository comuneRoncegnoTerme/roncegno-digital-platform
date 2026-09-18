#!/usr/bin/env sh
set -eu
ENV_FILE=${ENV_FILE:-.env.staging}
[ -f "$ENV_FILE" ] || { echo "File $ENV_FILE non trovato" >&2; exit 1; }
set -a
. "./$ENV_FILE"
set +a
URL=${PUBLIC_URL%/}/server/health
ATTEMPTS=${HEALTHCHECK_ATTEMPTS:-30}
SLEEP=${HEALTHCHECK_SLEEP_SECONDS:-5}
i=1
while [ "$i" -le "$ATTEMPTS" ]; do
  if curl -fsS "$URL" >/dev/null; then
    echo "Health check staging OK: $URL"
    exit 0
  fi
  echo "Tentativo $i/$ATTEMPTS non riuscito"
  i=$((i + 1))
  sleep "$SLEEP"
done
echo "Health check staging fallito: $URL" >&2
exit 1
