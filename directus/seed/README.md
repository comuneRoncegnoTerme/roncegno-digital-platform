# Visit Roncegno content seed

Seed iniziale per popolare Directus con contenuti turistici utili al portale Visit Roncegno.

## Contenuti inclusi

- 12 luoghi
- 8 percorsi/sentieri
- 10 eventi 2026

I dataset sono in JSON e vengono importati tramite `scripts/seed-content.py`.

## Sicurezza e idempotenza

Lo script:

- richiede un `DIRECTUS_TOKEN` esplicito;
- legge lo schema reale di Directus prima di scrivere;
- invia solo i campi effettivamente presenti nella collection;
- esegue upsert per `slug`, evitando duplicati ai run successivi;
- supporta `--dry-run` per verificare cosa verrebbe creato o aggiornato.

Non elimina contenuti esistenti.

## Dry run

```bash
DIRECTUS_URL=http://127.0.0.1:8055 \
DIRECTUS_TOKEN='...' \
make seed-content-dry-run
```

## Applicazione

```bash
DIRECTUS_URL=http://127.0.0.1:8055 \
DIRECTUS_TOKEN='...' \
make seed-content
```

## Fonti editoriali

I luoghi e i percorsi sono stati ricostruiti dai contenuti pubblici del portale storico Visit Roncegno, in particolare dalle sezioni dedicate a luoghi, percorsi, sentieri, terme e Circuito del Castagno.

Gli eventi di ottobre 2026 costituiscono il programma demo della Festa della Castagna 2026, adattato dal programma 2025 fornito per il progetto. Prima della pubblicazione definitiva date, artisti, costi e prenotazioni devono essere verificati dall'ufficio competente.

Le metriche dei percorsi sono valorizzate solo quando presenti nelle fonti disponibili; gli altri campi restano non impostati invece di essere stimati.
