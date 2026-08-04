# Architettura 0.1

```text
PostgreSQL 17 + PostGIS 3.5
          ↑
       Directus 11
          ↓ REST / GraphQL
  Visit Roncegno · Info screens · API pubblica
```

Il database è la sorgente primaria del modello. Directus fornisce Data Studio, autenticazione, file storage e API.

## Scelte

- UUID per tutte le entità principali.
- Coordinate in WGS84 (`SRID 4326`).
- Occorrenze evento materializzate in `event_occurrences`.
- Distribuzione separata dal contenuto tramite `distributions`.
- Tassonomie generiche e versionabili.
- Integrazione OpenCity esclusa dalla 0.1.
