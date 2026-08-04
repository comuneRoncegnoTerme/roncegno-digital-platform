# Roncegno Digital Platform 0.2

Content Hub multicanale basato su Directus, PostgreSQL/PostGIS e Redis.

## Ambienti

- **Sviluppo locale:** `docker-compose.yml`
- **Produzione/staging:** `docker-compose.yml` + `compose.production.yaml`

## Avvio locale

```bash
cp .env.example .env
docker compose up -d
```

Directus: `http://localhost:8055`

## Avvio produzione

```bash
cp .env.production.example .env.production
./scripts/generate-secrets.sh
# compilare .env.production
./scripts/production-up.sh
./scripts/production-healthcheck.sh
```

## Componenti

- Directus 11, con versione bloccabile
- PostgreSQL 17 + PostGIS 3.5
- Redis per cache e rate limiter
- Caddy per HTTPS e reverse proxy
- backup e restore di database/upload
- deploy controllato con health check
- workflow GitHub Actions di validazione

## Script principali

```bash
./scripts/start.sh
./scripts/production-up.sh
./scripts/production-status.sh
./scripts/production-healthcheck.sh
./scripts/backup.sh
./scripts/deploy.sh
```

## Documentazione

- `docs/architecture.md`
- `docs/content-model.md`
- `docs/production.md`
- `docs/runbook.md`

## Sicurezza

Non versionare `.env` o `.env.production`. Prima dell’esercizio reale configurare backup esterno, firewall, DNS, utenti nominali e test di ripristino.
