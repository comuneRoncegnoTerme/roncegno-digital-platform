# Ambiente di staging

Lo staging è l'ambiente di verifica prima della produzione. Deve avere database, Redis, upload, credenziali e dominio separati dalla produzione.

## Topologia consigliata

Usare una VPS/VM distinta dalla produzione:

- `staging-hub.example.it`
- stack Docker `roncegno-staging`
- PostgreSQL staging
- Redis staging
- Directus staging
- volumi staging indipendenti

Questa è la configurazione più sicura perché sia produzione sia staging espongono Caddy su 80/443. Se in futuro si vuole ospitare entrambi sulla stessa VPS, prima va estratto il reverse proxy in uno stack edge condiviso.

## Branching

- `main`: produzione
- `develop`: staging
- `feature/*`: sviluppo

Flusso ordinario:

`feature/* -> PR -> develop -> staging -> verifica -> PR develop -> main -> produzione`

## Prima installazione

Sul server staging:

```bash
git clone <repository>
cd roncegno-digital-platform
git checkout develop
cp .env.staging.example .env.staging
./scripts/generate-secrets.sh
# copiare i segreti generati in .env.staging e impostare dominio/CORS
./scripts/staging-up.sh
./scripts/migrate.sh
./scripts/staging-healthcheck.sh
```

Per le migrazioni usare:

```bash
ENV_FILE=.env.staging COMPOSE_PROJECT_NAME=roncegno-staging ./scripts/migrate.sh
```

Nota: lo script `migrate.sh` usa il servizio `database` del progetto Docker corrente. Per lo staging eseguire il comando dalla directory dello stack staging.

## Deploy

```bash
./scripts/staging-deploy.sh
```

Lo script è volutamente vincolato al branch `develop`.

## GitHub Actions

Il workflow CI valida shell script e file Compose su PR e push verso `develop` e `main`.

Il workflow di deploy staging è inizialmente manuale (`workflow_dispatch`). Configurare l'environment GitHub `staging` con:

- `STAGING_HOST`
- `STAGING_USER`
- `STAGING_SSH_KEY`
- `STAGING_PATH`

Dopo il primo deploy riuscito, il trigger può essere esteso a ogni push su `develop`.

## Produzione

La produzione resta su `main`. Il deploy produttivo deve essere avviato solo dopo la verifica dello staging e con approvazione umana.

Non usare mai credenziali, database o volumi di produzione nello staging.
