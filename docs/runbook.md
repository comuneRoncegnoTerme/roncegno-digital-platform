# Runbook operativo

## Verifiche giornaliere

```bash
./scripts/production-status.sh
./scripts/production-healthcheck.sh
```

## Log

```bash
docker compose -f compose.production.yaml --env-file .env.production logs --tail=200 directus
docker compose -f compose.production.yaml --env-file .env.production logs --tail=200 caddy
```

## Riavvio controllato

```bash
docker compose -f compose.production.yaml --env-file .env.production restart directus
```

## Incidenti

1. Verificare spazio disco: `df -h`.
2. Verificare container: `./scripts/production-status.sh`.
3. Consultare log Directus, database e Caddy.
4. Non cancellare volumi.
5. Prima di modifiche invasive eseguire `./scripts/backup.sh`.

## Test di ripristino

Eseguire almeno trimestralmente su staging, non direttamente in produzione.
