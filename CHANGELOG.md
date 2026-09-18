# Changelog

## 0.3.1 — Staging & CI/CD

- Introdotto branch `develop` come linea di integrazione per lo staging.
- Aggiunto stack Docker staging isolato con PostgreSQL, Redis, Directus e Caddy dedicati.
- Aggiunti script di avvio, stato, health check e deploy dello staging.
- Reso il deploy di produzione esplicitamente vincolato al branch `main`.
- Reso lo script migrazioni configurabile per file Compose e project name.
- Aggiunta CI GitHub Actions per validare shell script e configurazioni Compose.
- Aggiunto workflow manuale per il deploy remoto dello staging.
- Documentato il flusso `feature/* -> develop -> staging -> main -> produzione`.

## 0.3.0 — Editorial Studio

- Migrazione incrementale applicabile alla 0.2 senza reset del database.
- Workflow editoriale e campi di programmazione contenuti.
- Collezione `editorial_reviews`.
- Validazioni database prima di approvazione e pubblicazione.
- Sincronizzazione automatica delle occorrenze per eventi singoli.
- Funzione di aggiornamento degli stati programmati.
- Viste `hub_calendar`, `hub_upcoming_events`, `hub_today`, `hub_public_events` e `hub_editorial_dashboard`.
- Script di migrazione, verifica e refresh pubblicazioni.
- Guida completa alla configurazione del Data Studio Directus.
- Matrice dei permessi e query API di esempio.

## 0.2.0 — Production Ready

- Compose di produzione, Caddy, Redis, backup, restore, deploy e health check.

## 0.1.0 — Hub Foundation

- Schema core, Directus, PostgreSQL/PostGIS e dati seed.
