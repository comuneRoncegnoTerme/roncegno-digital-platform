BEGIN;

CREATE TABLE IF NOT EXISTS hub_schema_migrations (
  version varchar(40) PRIMARY KEY,
  applied_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE events ADD COLUMN IF NOT EXISTS editorial_notes text;
ALTER TABLE events ADD COLUMN IF NOT EXISTS publish_from timestamptz;
ALTER TABLE events ADD COLUMN IF NOT EXISTS publish_until timestamptz;
ALTER TABLE events ADD COLUMN IF NOT EXISTS review_due_at timestamptz;

ALTER TABLE places ADD COLUMN IF NOT EXISTS editorial_notes text;
ALTER TABLE places ADD COLUMN IF NOT EXISTS featured boolean NOT NULL DEFAULT false;
ALTER TABLE places ADD COLUMN IF NOT EXISTS editorial_priority integer NOT NULL DEFAULT 0;

ALTER TABLE organizations ADD COLUMN IF NOT EXISTS editorial_notes text;

CREATE TABLE IF NOT EXISTS editorial_reviews (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  content_collection varchar(100) NOT NULL,
  content_id uuid NOT NULL,
  review_status varchar(30) NOT NULL DEFAULT 'pending',
  assigned_to uuid,
  requested_by uuid,
  notes text,
  decision_notes text,
  requested_at timestamptz NOT NULL DEFAULT now(),
  decided_at timestamptz,
  date_created timestamptz NOT NULL DEFAULT now(),
  date_updated timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT editorial_review_status CHECK (review_status IN ('pending','approved','changes_requested','cancelled'))
);

CREATE INDEX IF NOT EXISTS editorial_reviews_content_idx
  ON editorial_reviews(content_collection, content_id);
CREATE INDEX IF NOT EXISTS editorial_reviews_status_idx
  ON editorial_reviews(review_status, requested_at);

CREATE OR REPLACE FUNCTION hub_touch_updated_at()
RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  NEW.date_updated := now();
  RETURN NEW;
END;
$$;

DO $$
DECLARE
  table_name text;
BEGIN
  FOREACH table_name IN ARRAY ARRAY[
    'taxonomies','taxonomy_terms','channels','organizations','places','events',
    'event_occurrences','distributions','screens','playlists','screen_overrides',
    'editorial_reviews'
  ]
  LOOP
    EXECUTE format('DROP TRIGGER IF EXISTS %I_touch_updated_at ON %I', table_name, table_name);
    EXECUTE format(
      'CREATE TRIGGER %I_touch_updated_at BEFORE UPDATE ON %I FOR EACH ROW EXECUTE FUNCTION hub_touch_updated_at()',
      table_name, table_name
    );
  END LOOP;
END;
$$;

CREATE OR REPLACE FUNCTION hub_sync_single_event_occurrence()
RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  IF NEW.schedule_type = 'single' THEN
    INSERT INTO event_occurrences(event,start_datetime,end_datetime,all_day,status,place_override,location_override)
    VALUES (
      NEW.id,
      NEW.start_datetime,
      NEW.end_datetime,
      NEW.all_day,
      CASE WHEN NEW.status = 'cancelled' THEN 'cancelled'::editorial_status ELSE 'published'::editorial_status END,
      NULL,
      NULL
    )
    ON CONFLICT (event,start_datetime)
    DO UPDATE SET
      end_datetime = EXCLUDED.end_datetime,
      all_day = EXCLUDED.all_day,
      status = EXCLUDED.status,
      date_updated = now();

    DELETE FROM event_occurrences
    WHERE event = NEW.id AND start_datetime <> NEW.start_datetime;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS events_sync_single_occurrence ON events;
CREATE TRIGGER events_sync_single_occurrence
AFTER INSERT OR UPDATE OF start_datetime,end_datetime,all_day,status,schedule_type
ON events
FOR EACH ROW EXECUTE FUNCTION hub_sync_single_event_occurrence();

CREATE OR REPLACE FUNCTION hub_validate_event_for_publication()
RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  IF NEW.status IN ('approved','scheduled','published') THEN
    IF nullif(trim(NEW.title),'') IS NULL THEN
      RAISE EXCEPTION 'Titolo obbligatorio per approvare o pubblicare un evento';
    END IF;
    IF nullif(trim(NEW.abstract),'') IS NULL THEN
      RAISE EXCEPTION 'Abstract obbligatorio per approvare o pubblicare un evento';
    END IF;
    IF nullif(trim(NEW.description),'') IS NULL THEN
      RAISE EXCEPTION 'Descrizione obbligatoria per approvare o pubblicare un evento';
    END IF;
    IF NEW.place IS NULL AND nullif(trim(NEW.address_override),'') IS NULL AND NOT NEW.online_event THEN
      RAISE EXCEPTION 'Indicare un luogo, un indirizzo alternativo o impostare evento online';
    END IF;
    IF NEW.publish_until IS NOT NULL AND NEW.publish_from IS NOT NULL AND NEW.publish_until < NEW.publish_from THEN
      RAISE EXCEPTION 'La fine pubblicazione non può precedere l’inizio';
    END IF;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS events_validate_publication ON events;
CREATE TRIGGER events_validate_publication
BEFORE INSERT OR UPDATE ON events
FOR EACH ROW EXECUTE FUNCTION hub_validate_event_for_publication();

CREATE OR REPLACE FUNCTION hub_refresh_publication_statuses()
RETURNS void LANGUAGE plpgsql AS $$
BEGIN
  UPDATE events
  SET status = 'published'
  WHERE status = 'scheduled'
    AND publish_from IS NOT NULL
    AND publish_from <= now()
    AND (publish_until IS NULL OR publish_until >= now());

  UPDATE events
  SET status = 'archived'
  WHERE status IN ('scheduled','published')
    AND publish_until IS NOT NULL
    AND publish_until < now();

  UPDATE distributions
  SET status = 'active', last_published_at = COALESCE(last_published_at, now())
  WHERE enabled = true
    AND status IN ('pending','scheduled')
    AND (publish_from IS NULL OR publish_from <= now())
    AND (publish_until IS NULL OR publish_until >= now());

  UPDATE distributions
  SET status = 'expired'
  WHERE status IN ('pending','scheduled','active')
    AND publish_until IS NOT NULL
    AND publish_until < now();
END;
$$;

CREATE OR REPLACE VIEW hub_calendar AS
SELECT
  o.id,
  o.event,
  e.identifier,
  e.slug,
  e.title,
  e.short_title,
  e.status AS event_status,
  o.status AS occurrence_status,
  o.start_datetime,
  o.end_datetime,
  o.all_day,
  COALESCE(po.id,p.id) AS place_id,
  COALESCE(po.name,p.name,e.address_override) AS place_name,
  COALESCE(o.location_override,p.location,e.location) AS location,
  e.featured,
  e.editorial_priority
FROM event_occurrences o
JOIN events e ON e.id=o.event
LEFT JOIN places p ON p.id=e.place
LEFT JOIN places po ON po.id=o.place_override;

CREATE OR REPLACE VIEW hub_upcoming_events AS
SELECT *
FROM hub_calendar
WHERE start_datetime >= date_trunc('day', now())
  AND start_datetime < now() + interval '90 days'
  AND event_status <> 'archived'
  AND occurrence_status <> 'cancelled';

CREATE OR REPLACE VIEW hub_public_events AS
SELECT DISTINCT
  e.id,
  e.identifier,
  e.slug,
  e.title,
  e.short_title,
  e.abstract,
  e.description,
  e.start_datetime,
  e.end_datetime,
  e.all_day,
  e.timezone,
  e.place,
  p.name AS place_name,
  p.slug AS place_slug,
  e.address_override,
  COALESCE(e.location,p.location) AS location,
  e.is_free,
  e.cost_notes,
  e.booking_required,
  e.booking_url,
  e.cover_image,
  e.poster,
  e.featured,
  e.editorial_priority,
  e.date_updated
FROM events e
LEFT JOIN places p ON p.id=e.place
JOIN distributions d ON d.content_collection='events' AND d.content_id=e.id
JOIN channels c ON c.id=d.channel
WHERE e.status='published'
  AND d.enabled=true
  AND d.status='active'
  AND c.active=true
  AND c.key IN ('visit_roncegno','public_api')
  AND (e.publish_from IS NULL OR e.publish_from <= now())
  AND (e.publish_until IS NULL OR e.publish_until >= now());

CREATE OR REPLACE VIEW hub_editorial_dashboard AS
SELECT
  (SELECT count(*) FROM events WHERE status='draft') AS events_draft,
  (SELECT count(*) FROM events WHERE status='review') AS events_in_review,
  (SELECT count(*) FROM events WHERE status='scheduled') AS events_scheduled,
  (SELECT count(*) FROM events WHERE status='published') AS events_published,
  (SELECT count(*) FROM hub_upcoming_events WHERE start_datetime < now() + interval '7 days') AS events_next_7_days,
  (SELECT count(*) FROM editorial_reviews WHERE review_status='pending') AS reviews_pending,
  (SELECT count(*) FROM distributions WHERE status='error') AS distributions_error,
  (SELECT count(*) FROM events WHERE cover_image IS NULL AND poster IS NULL AND status NOT IN ('archived','cancelled')) AS events_without_media,
  now() AS generated_at;

CREATE OR REPLACE VIEW hub_today AS
SELECT *
FROM hub_calendar
WHERE start_datetime < date_trunc('day', now()) + interval '1 day'
  AND COALESCE(end_datetime,start_datetime) >= date_trunc('day', now())
  AND event_status='published'
  AND occurrence_status <> 'cancelled'
ORDER BY featured DESC, editorial_priority DESC, start_datetime ASC;

INSERT INTO hub_schema_migrations(version)
VALUES ('0.3.0-editorial-studio')
ON CONFLICT (version) DO NOTHING;

COMMIT;
