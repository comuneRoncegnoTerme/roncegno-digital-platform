# Roncegno Digital Platform 0.4

Content Hub multicanale basato su Directus, PostgreSQL/PostGIS e Redis.

## AI Social Editorial 0.4

La 0.4 introduce una redazione generale sopra il Content Hub:

- contenuti editoriali indipendenti dal canale;
- routing separato Instagram/Facebook;
- bozze per canale in `distributions`;
- metadati AI;
- approvazione umana obbligatoria per le distribuzioni generate dall'AI;
- calendario e coda editoriale.

Migrazione:

```bash
sh ./scripts/migrate.sh
sh ./scripts/verify-ai-social-editorial.sh
```

Documentazione: `docs/ai-social-editorial.md` e `docs/ai-editorial-agent.md`.

## Editorial Studio 0.3

La release 0.3 ha introdotto workflow editoriale, revisioni, programmazione, sincronizzazione delle occorrenze e viste API per dashboard, calendario, eventi pubblici e “Roncegno oggi”.

## Ambienti

- **Sviluppo locale:** `docker-compose.yml`
- **Staging:** `compose.staging.yaml`, branch `develop`
- **Produzione:** `compose.production.yaml`, branch `main`

Flusso: `feature/* -> develop -> staging -> verifica -> main -> produzione`.

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
make ai-editorial-verify-staging
```

Lo staging deve usare database, upload, Redis e credenziali separati. Consulta `docs/staging.md`.

## Avvio produzione

```bash
cp .env.production.example .env.production
sh ./scripts/generate-secrets.sh
# compilare .env.production
sh ./scripts/production-up.sh
sh ./scripts/production-healthcheck.sh
```

## Componenti

- Directus 11
- PostgreSQL 17 + PostGIS 3.5
- Redis
- Caddy
- backup e restore
- workflow GitHub Actions
- modello editoriale multicanale con human approval

## Script principali

```bash
sh ./scripts/start.sh
sh ./scripts/staging-up.sh
sh ./scripts/staging-healthcheck.sh
sh ./scripts/staging-deploy.sh
sh ./scripts/production-up.sh
sh ./scripts/production-healthcheck.sh
sh ./scripts/backup.sh
sh ./scripts/deploy.sh
sh ./scripts/verify-ai-social-editorial.sh
```

## Documentazione

- `docs/architecture.md`
- `docs/content-model.md`
- `docs/directus-editorial-studio.md`
- `docs/ai-social-editorial.md`
- `docs/ai-editorial-agent.md`
- `docs/staging.md`
- `docs/production.md`

## Sicurezza

Non versionare `.env`, `.env.staging` o `.env.production`. Staging e produzione non devono condividere database, volumi o segreti. Le distribuzioni AI richiedono approvazione umana prima di poter diventare approvate, programmate o pubblicate.
