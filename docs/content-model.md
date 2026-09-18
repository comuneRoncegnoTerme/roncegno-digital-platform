# Modello contenuti

## Core

- `events`: contenuto editoriale dell'evento.
- `event_occurrences`: date concrete interrogabili.
- `places`: luoghi e geometrie.
- `organizations`: enti, associazioni e operatori.
- `taxonomies` / `taxonomy_terms`: classificazioni condivise.
- `channels` / `distributions`: pubblicazione multicanale.

## Redazione generale 0.4

- `editorial_contents`: argomento/briefing editoriale indipendente dal canale.
- `editorial_contents_taxonomy_terms`: tassonomie aggiuntive del contenuto.
- `editorial_content_files`: asset e fonti documentali.
- `editorial_channel_decisions`: routing esplicito per ciascun canale.
- `distributions`: output concreto per canale, con stato editoriale e stato tecnico separati.

Un contenuto può avere zero, una o più distribuzioni. Instagram e Facebook non sono sincronizzati 1:1.

## Canali social

- `instagram`
- `facebook`

Sono registrati in `channels` come target esterni.

## Stati

Contenuto/distribuzione editoriale:

`draft → review → approved → scheduled → published → archived`

Stato aggiuntivo: `cancelled`.

Consegna tecnica di `distributions`:

`disabled | pending | scheduled | active | expired | error`

Le due dimensioni sono volutamente separate.

## Digital signage

- `screens`
- `playlists`
- `playlist_items`
- `screen_overrides`
