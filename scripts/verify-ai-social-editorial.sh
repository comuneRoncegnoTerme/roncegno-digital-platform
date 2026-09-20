#!/usr/bin/env sh
set -eu

ENV_FILE=${ENV_FILE:-.env}
COMPOSE_FILE=${COMPOSE_FILE:-docker-compose.yml}
PROJECT_NAME=${COMPOSE_PROJECT_NAME:-}

[ -f "$ENV_FILE" ] || { echo "File $ENV_FILE non trovato" >&2; exit 1; }
[ -f "$COMPOSE_FILE" ] || { echo "File Compose $COMPOSE_FILE non trovato" >&2; exit 1; }

set -a
. "./$ENV_FILE"
set +a

compose_exec() {
  if [ -n "$PROJECT_NAME" ]; then
    docker compose -p "$PROJECT_NAME" -f "$COMPOSE_FILE" --env-file "$ENV_FILE" exec -T database "$@"
  else
    docker compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" exec -T database "$@"
  fi
}

compose_exec psql -v ON_ERROR_STOP=1 -U "$DB_USER" -d "$DB_DATABASE" <<'SQL'
DO $$
BEGIN
  IF to_regclass('public.editorial_contents') IS NULL THEN
    RAISE EXCEPTION 'editorial_contents non presente';
  END IF;
  IF to_regclass('public.editorial_channel_decisions') IS NULL THEN
    RAISE EXCEPTION 'editorial_channel_decisions non presente';
  END IF;
  IF to_regclass('public.hub_editorial_content_queue') IS NULL THEN
    RAISE EXCEPTION 'hub_editorial_content_queue non presente';
  END IF;
  IF to_regclass('public.hub_social_calendar') IS NULL THEN
    RAISE EXCEPTION 'hub_social_calendar non presente';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM channels WHERE key='instagram' AND active=true) THEN
    RAISE EXCEPTION 'Canale Instagram non presente o non attivo';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM channels WHERE key='facebook' AND active=true) THEN
    RAISE EXCEPTION 'Canale Facebook non presente o non attivo';
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema='public' AND table_name='distributions' AND column_name='editorial_state'
  ) THEN
    RAISE EXCEPTION 'distributions.editorial_state non presente';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM hub_schema_migrations WHERE version='0.4.0-ai-social-editorial') THEN
    RAISE EXCEPTION 'Migrazione 0.4 non registrata';
  END IF;
END $$;
SQL

echo "Verifica AI Social Editorial 0.4 completata."
