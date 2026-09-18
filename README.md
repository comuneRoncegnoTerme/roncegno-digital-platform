# Roncegno Digital Platform 0.3

Content Hub multicanale basato su Directus, PostgreSQL/PostGIS e Redis.

## Editorial Studio 0.3

Dopo l’avvio della piattaforma esistente, applica la migrazione senza cancellare i dati:

```bash
sh ./scripts/migrate.sh
sh ./scripts/verify-editorial-studio.sh
```

La release aggiunge workflow editoriale, revisioni, programmazione, sincronizzazione delle occorrenze e viste API per dashboard, calendario, eventi pubblici e “Roncegno oggi”. Consulta `docs/directus-editorial-studio.md`.

## Ambienti

- **Sviluppo locale:** `docker-compose.yml`
- **Staging:** `compose.staging.yaml`, branch `develop`
- **Produzione:** `compose.production.yaml`, branch `main`

Il flusso previsto è `feature/* -> develop -> staging -> verifica -> main -> produzione`.

## Avvio locale

```bash
cp .env.example .env
docker compose up -d
```

Directus: `http://localhost:8055`

## Avvio staging

```bash
cp .env.staging.example .env.staging
# compilare .env.staging con segreti e dominio dedicati
sh ./scripts/staging-up.sh
make migrate-staging
sh ./scripts/staging-healthcheck.sh
```

Lo staging deve usare database, upload, Redis e credenziali separati. È consigliata una VPS/VM distinta dalla produzione. Consulta `docs/staging.md`.

## Avvio produzione

```bash
cp .env.production.example .env.production
sh ./scripts/generate-secrets.sh
# compilare .env.production
sh ./scripts/production-up.sh
sh ./scripts/production-healthcheck.sh
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
sh ./scripts/start.sh
sh ./scripts/staging-up.sh
sh ./scripts/staging-healthcheck.sh
sh ./scripts/staging-deploy.sh
sh ./scripts/production-up.sh
sh ./scripts/production-status.sh
sh ./scripts/production-healthcheck.sh
sh ./scripts/backup.sh
sh ./scripts/deploy.sh
```

## Documentazione

- `docs/architecture.md`
- `docs/content-model.md`
- `docs/directus-editorial-studio.md`
- `docs/staging.md`
- `docs/production.md`
- `docs/runbook.md`

## Sicurezza

Non versionare `.env`, `.env.staging` o `.env.production`. Staging e produzione non devono condividere database, volumi o segreti.
