# AI Social Editorial 0.4

La release 0.4 estende il Content Hub da CMS eventi a redazione digitale multicanale con supporto AI e approvazione umana.

## Principio

Un **contenuto madre** non coincide con un post.

```text
editorial_contents
        |
        +--> editorial_channel_decisions --> Instagram: publish
        |                              \--> Facebook: skip
        |
        +--> distributions --> Instagram / carousel / caption / schedule
```

Instagram e Facebook sono linee editoriali autonome. Una distribuzione viene creata solo quando serve.

## Collezioni

### `editorial_contents`

Rappresenta l'argomento o il briefing editoriale: ordinanza, aggiornamento lavori, idea, comunicato, servizio, racconto, ecc.

Campi principali:

- `status`: workflow editoriale;
- `title`, `summary`, `briefing`;
- `content_type`, `primary_category`;
- `urgency`, `editorial_priority`;
- `source_type`, `source_url`, `source_file`, `source_collection`, `source_id`;
- `factual_notes`: fatti che l'AI non deve alterare;
- `ai_generated`, `ai_model`, `ai_generated_at`, `ai_notes`.

### `editorial_channel_decisions`

Registra il routing per canale:

- `publish`: il contenuto merita una distribuzione sul canale;
- `hold`: valutazione rinviata;
- `skip`: contenuto esplicitamente non destinato al canale.

Conserva formato suggerito, motivazione e confidenza.

### `distributions`

Rimane l'oggetto di pubblicazione per canale. La 0.4 aggiunge:

- `editorial_state`: stato editoriale separato dallo stato tecnico di consegna;
- `format`, `headline`, `body`, `call_to_action`, `alt_text`, `visual_direction`;
- metadati AI;
- `approved_by`, `approved_at`;
- `published_at`, `performance_data`.

## Regola di sicurezza AI

Se `ai_generated=true`, una distribuzione non può passare a `approved`, `scheduled` o `published` senza `approved_by`.

Il database applica questa regola tramite trigger. Non è quindi affidata soltanto all'interfaccia o al prompt.

## Routing editoriale iniziale

Linee guida, non automatismi rigidi:

| Contenuto | Instagram | Facebook |
|---|---|---|
| Avviso urgente / viabilità | pubblica se rilevante, spesso post o story | pubblica |
| Ordinanza | sintesi visuale se impatta molte persone | spiegazione più completa |
| Evento principale | visuale, carousel/reel/story | informativo, se utile |
| Giovani / sport / comunità | prioritario | selettivo |
| Rendiconto amministrativo | selettivo | prioritario |
| Storytelling territoriale | prioritario | solo se adatto |
| Contenuto duplicativo o debole | skip | skip/hold |

Il router deve sempre considerare lo storico recente prima di proporre il canale.

## Directus

Configurare in Data Model:

- **Contenuti editoriali** → `editorial_contents`, display `{{title}}`;
- **Decisioni canale** → `editorial_channel_decisions`;
- **Distribuzioni** → mantenere la collection esistente, mostrando anche `editorial_state`.

Viste sola lettura:

- `hub_editorial_content_queue`;
- `hub_social_calendar`;
- `hub_editorial_dashboard`.

Dashboard **Redazione**:

- coda contenuti;
- calendario social;
- contenuti urgenti;
- revisioni pendenti;
- errori di distribuzione.

## Flusso AI

```text
Fonte / input umano
      |
      v
editorial_contents (draft)
      |
      v
AI router
      |
      +--> decisione Instagram
      +--> decisione Facebook
      |
      v
bozze distributions
      |
      v
review umana
      |
      v
approved / scheduled
      |
      v
publisher
```

L'AI può creare bozze e suggerire routing. Non deve poter auto-approvare né pubblicare autonomamente.
