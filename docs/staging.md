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
sh ./scripts/generate-secrets.sh
# copiare i segreti generati in .env.staging e impostare dominio/CORS
sh ./scripts/staging-up.sh
make migrate-staging
sh ./scripts/staging-healthcheck.sh
```

Le migrazioni staging possono essere eseguite anche esplicitamente:

```bash
ENV_FILE=.env.staging \
COMPOSE_FILE=compose.staging.yaml \
COMPOSE_PROJECT_NAME=roncegno-staging \
sh ./scripts/migrate.sh
```

## Deploy

```bash
sh ./scripts/staging-deploy.sh
```

Lo script è volutamente vincolato al branch `develop`.

## GitHub Actions

Il workflow CI valida shell script e file Compose su PR e push verso `develop` e `main`.

Il workflow di deploy staging è inizialmente manuale (`workflow_dispatch`). Configurare l'environment GitHub `staging` con i seguenti secret:

- `STAGING_HOST`
- `STAGING_USER`
- `STAGING_SSH_KEY`
- `STAGING_PATH`

Dopo il primo deploy riuscito, il trigger può essere esteso a ogni push su `develop`.

Per la produzione creare un environment GitHub `production` con approvazione obbligatoria prima di introdurre un deploy automatico. Fino ad allora, il deploy produttivo resta manuale tramite `scripts/deploy.sh`.

## Produzione

La produzione resta su `main`. `scripts/deploy.sh` è vincolato a `main` e non accetta più un branch arbitrario.

Attenzione: eventuali webhook, cron o servizi esterni già presenti sul VPS non sono definiti in questa repository. Prima di considerarli disattivati va verificata la configurazione del server di produzione.

Non usare mai credenziali, database o volumi di produzione nello staging.
