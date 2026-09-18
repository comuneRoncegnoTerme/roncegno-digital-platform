# Permessi AI Social Editorial 0.4

L'AI non deve utilizzare un token amministratore Directus.

## Ruoli

### AI Editorial Agent

Permessi minimi:

- `editorial_contents`: read, create, update;
- `editorial_channel_decisions`: read, create, update;
- `distributions`: read, create, update limitato alle bozze generate dall'AI;
- `channels`, `taxonomies`, `taxonomy_terms`: read;
- `events`, `places`, `organizations`: read;
- `hub_editorial_content_queue`, `hub_social_calendar`: read;
- file pubblici/editoriali necessari: read.

Restrizioni:

- non può valorizzare `approved_by` o `approved_at`;
- non può impostare `editorial_state` oltre `draft` / `review`;
- non può impostare una distribuzione a `active`;
- non può cancellare contenuti approvati o pubblicati;
- non può modificare configurazione dei canali.

### Editor

Può:

- creare e modificare contenuti;
- correggere copy/asset;
- portare contenuti a `review`;
- richiedere una revisione.

Non dovrebbe pubblicare direttamente se si vuole separazione dei compiti.

### Approver

Può:

- approvare/richiedere modifiche;
- valorizzare `approved_by`;
- impostare `approved` / `scheduled`;
- annullare una distribuzione.

### Publisher

Token tecnico separato, da introdurre quando collegheremo Meta API.

Può:

- leggere solo distribuzioni `approved` / `scheduled`;
- aggiornare esclusivamente stato tecnico, `external_id`, `external_uri`, `published_at`, `last_error` e metriche;
- non può modificare il copy approvato.

## Human-in-the-loop

Il database contiene una seconda barriera: se `ai_generated=true`, il passaggio a `approved`, `scheduled` o `published` senza `approved_by` viene rifiutato.

La regola deve essere mantenuta anche quando saranno introdotti Directus Flow, n8n, OpenAI API o Meta Graph API.

## Service account

Creare account/token tecnici distinti per ambiente:

- `ai-agent-staging`
- `publisher-staging`
- `ai-agent-production`
- `publisher-production`

Non riutilizzare token tra staging e produzione.
