# Directus Editorial Studio 0.3

La release 0.3 aggiunge al database le viste e le regole necessarie per usare Directus come back office editoriale.

## 1. Applicare la migrazione

Dalla root del repository:

```bash
./scripts/migrate.sh
./scripts/verify-editorial-studio.sh
```

Su PowerShell, se gli script shell non sono eseguibili direttamente:

```powershell
docker compose exec -T database psql -U roncegno -d roncegno_hub -v ON_ERROR_STOP=1 -f /dev/stdin < infrastructure/postgres/migrations/030_editorial_studio.sql
```

In alternativa eseguire il file con Git Bash o WSL.

## 2. Collezioni editoriali

Impostare in **Settings → Data Model** le seguenti etichette e icone:

| Collezione | Etichetta | Icona | Modello di visualizzazione |
|---|---|---|---|
| `events` | Eventi | `event` | `{{title}} — {{start_datetime}}` |
| `event_occurrences` | Occorrenze | `event_repeat` | `{{event.title}} — {{start_datetime}}` |
| `places` | Luoghi | `place` | `{{name}}` |
| `organizations` | Organizzazioni | `groups` | `{{name}}` |
| `editorial_reviews` | Revisioni | `fact_check` | `{{content_collection}} — {{review_status}}` |
| `distributions` | Distribuzione | `send` | `{{channel.name}} — {{status}}` |
| `channels` | Canali | `hub` | `{{name}}` |
| `screens` | Schermi | `monitor` | `{{name}}` |
| `playlists` | Playlist | `playlist_play` | `{{name}}` |
| `taxonomies` | Tassonomie | `category` | `{{name}}` |
| `taxonomy_terms` | Voci tassonomia | `sell` | `{{label}}` |

Le viste `hub_calendar`, `hub_upcoming_events`, `hub_today`, `hub_public_events` e `hub_editorial_dashboard` devono essere configurate come **sola lettura**.

## 3. Interfacce campi Eventi

Configurazione consigliata:

- `status`: Select Dropdown con badge colorati.
- `title`, `short_title`, `identifier`, `slug`: Input.
- `abstract`: Textarea.
- `description`, `cost_notes`, `accessibility_notes`, `additional_information`: WYSIWYG.
- `start_datetime`, `end_datetime`, `publish_from`, `publish_until`, `review_due_at`: Datetime.
- `place`, `contact_organization`, `parent_event`: Many-to-One.
- `location`: Map.
- `cover_image`, `poster`: File Image.
- `featured`, `all_day`, `online_event`, `is_free`, `booking_required`: Toggle.
- `editorial_priority`: Slider 0–100.

Raggruppare i campi in pannelli:

1. **Identità** — status, identifier, slug, title, short_title, abstract, description.
2. **Data e programmazione** — schedule_type, start/end, all_day, recurrence_rule.
3. **Luogo** — place, address_override, location, online_event, online_url.
4. **Partecipazione** — gratuità, costi, prenotazione, capienza, accessibilità.
5. **Contatti** — organizzazione e riferimenti.
6. **Media** — cover, poster, video, crediti.
7. **Distribuzione editoriale** — featured, priority, publish_from/until, review_due_at, editorial_notes.

## 4. Workflow

Stati disponibili:

- `draft` — Bozza
- `review` — In revisione
- `approved` — Approvato
- `scheduled` — Programmato
- `published` — Pubblicato
- `cancelled` — Annullato
- `archived` — Archiviato

Il database blocca la pubblicazione se mancano titolo, abstract, descrizione e localizzazione.

## 5. Dashboard

Creare una Dashboard Directus denominata **Redazione** con:

- metriche tratte da `hub_editorial_dashboard`;
- calendario basato su `hub_calendar.start_datetime`;
- lista `hub_upcoming_events`, ordinata per data;
- lista `editorial_reviews` filtrata per `review_status = pending`;
- lista `distributions` filtrata per `status = error`.

## 6. Aggiornamento programmazioni

Per sviluppo locale:

```bash
./scripts/refresh-publication-statuses.sh
```

In produzione, eseguire ogni cinque minuti tramite cron:

```cron
*/5 * * * * cd /opt/roncegno/roncegno-digital-platform && ENV_FILE=.env.production ./scripts/refresh-publication-statuses.sh >> /var/log/roncegno-publication.log 2>&1
```

## 7. API già disponibili

- `/items/hub_today`
- `/items/hub_upcoming_events`
- `/items/hub_public_events`
- `/items/hub_calendar`

Assegnare al ruolo pubblico esclusivamente la lettura di `hub_public_events` e dei file effettivamente pubblici.
