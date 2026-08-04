# Roncegno Content Hub 0.1

Fondazione eseguibile per la gestione multicanale di eventi, luoghi, organizzazioni e contenuti per schermi.

## Requisiti

- Docker Engine
- Docker Compose v2
- almeno 2 GB di RAM disponibili

## Avvio

```bash
cp .env.example .env
```

Modificare obbligatoriamente password, `DIRECTUS_KEY` e `DIRECTUS_SECRET`, quindi:

```bash
./scripts/start.sh
```

Aprire:

```text
http://localhost:8055
```

Accedere con `ADMIN_EMAIL` e `ADMIN_PASSWORD` definiti in `.env`.

## Cosa viene creato

- Directus 11
- PostgreSQL 17 + PostGIS 3.5
- tassonomie e termini iniziali
- canali di distribuzione
- organizzazione Comune di Roncegno Terme
- tre luoghi demo
- evento e occorrenza demo
- schermo e playlist demo

## Comandi

```bash
./scripts/healthcheck.sh
./scripts/stop.sh
./scripts/reset.sh
./scripts/export-schema.sh
```

## Nota Directus

Le tabelle applicative vengono create al primo avvio tramite gli script SQL in `infrastructure/postgres/init`. Directus le rileva dal database. Nel Data Studio vanno poi configurate le presentazioni dei campi, le relazioni ai file, le Policies e i Flow. Dopo questa configurazione, esportare lo snapshot versionato.

## Sicurezza

Il file `.env` non deve essere committato. La configurazione inclusa è adatta allo sviluppo locale, non alla produzione.
