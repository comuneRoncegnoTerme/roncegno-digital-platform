# Adapter AI → Directus

La prima versione dell'integrazione è volutamente semplice e deterministica.

L'AI **non scrive SQL** e non usa un token amministratore. Produce un payload JSON conforme al contratto; l'adapter valida il payload, risolve tassonomie/canali e usa le API REST di Directus.

## Flusso

```text
ChatGPT / agente editoriale
        |
        v
JSON strutturato
        |
        v
scripts/ai-directus-adapter.py
        |
        v
Directus REST API
        |
        +--> editorial_contents
        +--> editorial_channel_decisions
        +--> distributions (solo publish)
```

## Variabili ambiente

```bash
export DIRECTUS_URL="https://staging-hub.example.it"
export DIRECTUS_TOKEN="TOKEN_SERVICE_ACCOUNT_AI"
```

Il token deve appartenere al ruolo `AI Editorial Agent`, non a un amministratore.

## Esecuzione

```bash
python3 scripts/ai-directus-adapter.py < examples/api/ai-editorial-payload.json
```

L'adapter è idempotente sui seguenti identificatori:

- `editorial_contents.identifier`;
- coppia contenuto/canale per `editorial_channel_decisions`;
- coppia contenuto/canale per `distributions`.

Rieseguire lo stesso payload aggiorna la bozza invece di crearne una duplicata.

## Contratto

Root:

- `content`: contenuto madre;
- `decisions[]`: una decisione per canale.

Una decisione può essere:

- `publish`: crea/aggiorna anche una distribution in stato `draft`;
- `hold`: registra solo la decisione;
- `skip`: registra solo la decisione.

## Sicurezza

L'adapter imposta sempre:

- `ai_generated=true`;
- `editorial_state=draft` sulle distribuzioni;
- nessun `approved_by`.

La barriera database della 0.4 impedisce comunque a una distribuzione AI di essere approvata o programmata senza intervento umano.

## Perché questa V1

Questa soluzione separa nettamente:

1. **ragionamento editoriale** — AI;
2. **contratto dati** — JSON;
3. **persistenza** — adapter;
4. **approvazione** — Directus/humans;
5. **pubblicazione futura** — publisher Meta separato.

Non serve ancora n8n. Se in seguito serviranno trigger automatici, polling o più provider, l'adapter potrà diventare un piccolo servizio HTTP mantenendo lo stesso contratto.
