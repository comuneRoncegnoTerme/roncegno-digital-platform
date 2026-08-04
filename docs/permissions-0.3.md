# Permessi Editorial Studio

## Communication Manager

CRUD su tutte le collezioni editoriali. Può impostare ogni stato e gestire distribuzioni, tassonomie e schermi.

## Editor

- CRUD su eventi, luoghi, organizzazioni e file propri.
- Può usare `draft` e `review`.
- Non può modificare `external_identifier`, `external_id`, `external_uri`, `last_error`.
- Non può pubblicare direttamente.

## Association Contributor

- Crea eventi sempre in `draft`.
- Legge e modifica solo eventi creati dall’utente o collegati all’organizzazione posseduta.
- Non gestisce distribuzioni e priorità editoriali.

Filtro suggerito sugli eventi:

```json
{
  "_or": [
    { "user_created": { "_eq": "$CURRENT_USER" } },
    {
      "organizers": {
        "organization": {
          "owner_user": { "_eq": "$CURRENT_USER" }
        }
      }
    }
  ]
}
```

## Public

Lettura esclusivamente su:

- `hub_public_events`
- luoghi con `status = published`
- organizzazioni con `status = published` e `public_profile = true`
- file referenziati da contenuti pubblici

Le viste dashboard e calendario editoriale non devono essere pubbliche.
