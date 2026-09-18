BEGIN;

CREATE TABLE IF NOT EXISTS hub_schema_migrations (
  version varchar(40) PRIMARY KEY,
  applied_at timestamptz NOT NULL DEFAULT now()
);

-- Generic editorial object: one topic/idea/source can produce zero or many channel distributions.
CREATE TABLE IF NOT EXISTS editorial_contents (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  status editorial_status NOT NULL DEFAULT 'draft',
  identifier varchar(140) NOT NULL UNIQUE,
  slug varchar(200) UNIQUE,
  title varchar(300) NOT NULL,
  summary text,
  briefing text,
  content_type uuid REFERENCES taxonomy_terms(id) ON DELETE SET NULL,
  primary_category uuid REFERENCES taxonomy_terms(id) ON DELETE SET NULL,
  urgency varchar(20) NOT NULL DEFAULT 'routine',
  editorial_priority integer NOT NULL DEFAULT 0,
  source_type varchar(30) NOT NULL DEFAULT 'manual',
  source_url text,
  source_file uuid,
  source_collection varchar(100),
  source_id uuid,
  factual_notes text,
  editorial_notes text,
  review_due_at timestamptz,
  owner_user uuid,
  ai_generated boolean NOT NULL DEFAULT false,
  ai_model varchar(120),
  ai_generated_at timestamptz,
  ai_notes text,
  date_created timestamptz NOT NULL DEFAULT now(),
  date_updated timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT editorial_content_urgency CHECK (urgency IN ('routine','timely','urgent','emergency')),
  CONSTRAINT editorial_content_priority CHECK (editorial_priority BETWEEN 0 AND 100),
  CONSTRAINT editorial_content_source_type CHECK (source_type IN ('manual','document','url','api','event','place','organization','other'))
);

CREATE TABLE IF NOT EXISTS editorial_contents_taxonomy_terms (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  content uuid NOT NULL REFERENCES editorial_contents(id) ON DELETE CASCADE,
  term uuid NOT NULL REFERENCES taxonomy_terms(id) ON DELETE CASCADE,
  relation_type varchar(60) NOT NULL,
  sort integer NOT NULL DEFAULT 0,
  UNIQUE(content, term, relation_type)
);

CREATE TABLE IF NOT EXISTS editorial_content_files (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  content uuid NOT NULL REFERENCES editorial_contents(id) ON DELETE CASCADE,
  file uuid NOT NULL,
  relation_type varchar(40) NOT NULL DEFAULT 'asset',
  sort integer NOT NULL DEFAULT 0,
  UNIQUE(content, file, relation_type)
);

-- Explicit routing decisions make "Instagram only", "Facebook only", cross-post and skip auditable.
CREATE TABLE IF NOT EXISTS editorial_channel_decisions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  content uuid NOT NULL REFERENCES editorial_contents(id) ON DELETE CASCADE,
  channel uuid NOT NULL REFERENCES channels(id) ON DELETE CASCADE,
  decision varchar(20) NOT NULL,
  recommended_format varchar(40),
  rationale text,
  confidence numeric(4,3),
  ai_generated boolean NOT NULL DEFAULT true,
  ai_model varchar(120),
  decided_by uuid,
  decided_at timestamptz NOT NULL DEFAULT now(),
  date_created timestamptz NOT NULL DEFAULT now(),
  date_updated timestamptz NOT NULL DEFAULT now(),
  UNIQUE(content, channel),
  CONSTRAINT editorial_channel_decision_value CHECK (decision IN ('publish','hold','skip')),
  CONSTRAINT editorial_channel_confidence CHECK (confidence IS NULL OR (confidence >= 0 AND confidence <= 1))
);

-- A distribution has two orthogonal states:
-- editorial_state = human/editorial workflow; status = operational delivery state.
ALTER TABLE distributions ADD COLUMN IF NOT EXISTS editorial_state editorial_status;
ALTER TABLE distributions ADD COLUMN IF NOT EXISTS format varchar(40);
ALTER TABLE distributions ADD COLUMN IF NOT EXISTS headline text;
ALTER TABLE distributions ADD COLUMN IF NOT EXISTS body text;
ALTER TABLE distributions ADD COLUMN IF NOT EXISTS call_to_action text;
ALTER TABLE distributions ADD COLUMN IF NOT EXISTS alt_text text;
ALTER TABLE distributions ADD COLUMN IF NOT EXISTS visual_direction text;
ALTER TABLE distributions ADD COLUMN IF NOT EXISTS route_reason text;
ALTER TABLE distributions ADD COLUMN IF NOT EXISTS ai_generated boolean NOT NULL DEFAULT false;
ALTER TABLE distributions ADD COLUMN IF NOT EXISTS ai_model varchar(120);
ALTER TABLE distributions ADD COLUMN IF NOT EXISTS ai_generated_at timestamptz;
ALTER TABLE distributions ADD COLUMN IF NOT EXISTS approved_by uuid;
ALTER TABLE distributions ADD COLUMN IF NOT EXISTS approved_at timestamptz;
ALTER TABLE distributions ADD COLUMN IF NOT EXISTS published_at timestamptz;
ALTER TABLE distributions ADD COLUMN IF NOT EXISTS performance_data jsonb NOT NULL DEFAULT '{}'::jsonb;
ALTER TABLE distributions ADD COLUMN IF NOT EXISTS source_decision uuid REFERENCES editorial_channel_decisions(id) ON DELETE SET NULL;

-- Existing 0.1/0.3 distributions predate the editorial_state field.
UPDATE distributions
SET editorial_state = CASE
  WHEN status = 'active' THEN 'published'::editorial_status
  WHEN status = 'scheduled' THEN 'scheduled'::editorial_status
  ELSE 'approved'::editorial_status
END
WHERE editorial_state IS NULL;

ALTER TABLE distributions ALTER COLUMN editorial_state SET DEFAULT 'draft';
ALTER TABLE distributions ALTER COLUMN editorial_state SET NOT NULL;

CREATE INDEX IF NOT EXISTS editorial_contents_status_idx
  ON editorial_contents(status, editorial_priority DESC, date_created DESC);
CREATE INDEX IF NOT EXISTS editorial_contents_category_idx
  ON editorial_contents(primary_category);
CREATE INDEX IF NOT EXISTS editorial_channel_decisions_content_idx
  ON editorial_channel_decisions(content, decision);
CREATE INDEX IF NOT EXISTS distributions_editorial_state_idx
  ON distributions(editorial_state, channel, publish_from);
CREATE INDEX IF NOT EXISTS distributions_content_idx
  ON distributions(content_collection, content_id);

-- Shared taxonomies for institutional communication.
INSERT INTO taxonomies (key,name,description,multiple,sort)
VALUES
  ('content_types','Tipi contenuto','Formato editoriale del contenuto madre',false,80),
  ('editorial_categories','Aree editoriali','Ambiti della comunicazione istituzionale',true,90)
ON CONFLICT (key) DO UPDATE SET
  name = EXCLUDED.name,
  description = EXCLUDED.description;

INSERT INTO taxonomy_terms (taxonomy,key,label,sort)
SELECT t.id,v.key,v.label,v.sort
FROM taxonomies t
JOIN (VALUES
  ('content_types','notice','Avviso',10),
  ('content_types','event_promo','Promozione evento',20),
  ('content_types','storytelling','Racconto',30),
  ('content_types','service','Servizio',40),
  ('content_types','public_works','Aggiornamento lavori',50),
  ('content_types','ordinance','Ordinanza',60),
  ('content_types','community','Comunità',70),
  ('content_types','recap','Recap',80),
  ('content_types','emergency','Emergenza',90),
  ('editorial_categories','administration','Amministrazione',10),
  ('editorial_categories','public_works','Lavori pubblici',20),
  ('editorial_categories','mobility','Viabilità e mobilità',30),
  ('editorial_categories','events','Eventi',40),
  ('editorial_categories','culture','Cultura',50),
  ('editorial_categories','sport','Sport',60),
  ('editorial_categories','youth','Giovani',70),
  ('editorial_categories','social','Sociale',80),
  ('editorial_categories','environment','Ambiente',90),
  ('editorial_categories','associations','Associazioni',100),
  ('editorial_categories','territory','Territorio',110),
  ('editorial_categories','tourism','Turismo',120)
) AS v(taxonomy_key,key,label,sort)
  ON t.key=v.taxonomy_key
ON CONFLICT (taxonomy,key) DO UPDATE SET
  label = EXCLUDED.label,
  sort = EXCLUDED.sort,
  active = true;

-- Social channels are external delivery targets. They remain separate editorial lines.
INSERT INTO channels (key,name,channel_type,description,active,sort)
VALUES
  ('instagram','Instagram','external','Canale Instagram istituzionale del Comune',true,70),
  ('facebook','Facebook','external','Canale Facebook istituzionale del Comune',true,80)
ON CONFLICT (key) DO UPDATE SET
  name = EXCLUDED.name,
  description = EXCLUDED.description,
  active = true,
  sort = EXCLUDED.sort;

CREATE OR REPLACE FUNCTION hub_validate_editorial_content()
RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  IF NEW.status IN ('approved','scheduled','published') THEN
    IF nullif(trim(NEW.title),'') IS NULL THEN
      RAISE EXCEPTION 'Titolo obbligatorio per approvare o pubblicare un contenuto editoriale';
    END IF;
    IF nullif(trim(COALESCE(NEW.briefing,'')),'') IS NULL
       AND nullif(trim(COALESCE(NEW.factual_notes,'')),'') IS NULL THEN
      RAISE EXCEPTION 'Briefing o note fattuali obbligatorie prima dell’approvazione';
    END IF;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS editorial_contents_validate ON editorial_contents;
CREATE TRIGGER editorial_contents_validate
BEFORE INSERT OR UPDATE ON editorial_contents
FOR EACH ROW EXECUTE FUNCTION hub_validate_editorial_content();

CREATE OR REPLACE FUNCTION hub_validate_distribution_editorial_state()
RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  IF NEW.ai_generated
     AND NEW.editorial_state IN ('approved','scheduled','published')
     AND NEW.approved_by IS NULL THEN
    RAISE EXCEPTION 'Una distribuzione generata dall''AI richiede approvazione umana';
  END IF;

  IF NEW.approved_by IS NOT NULL AND NEW.approved_at IS NULL THEN
    NEW.approved_at := now();
  END IF;

  IF NEW.status = 'active'
     AND NEW.editorial_state NOT IN ('approved','scheduled','published') THEN
    RAISE EXCEPTION 'Una distribuzione non approvata non può diventare attiva';
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS distributions_validate_editorial_state ON distributions;
CREATE TRIGGER distributions_validate_editorial_state
BEFORE INSERT OR UPDATE ON distributions
FOR EACH ROW EXECUTE FUNCTION hub_validate_distribution_editorial_state();

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
  SET status = 'active',
      last_published_at = COALESCE(last_published_at, now())
  WHERE enabled = true
    AND editorial_state IN ('approved','scheduled','published')
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
    'editorial_contents',
    'editorial_channel_decisions'
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

CREATE OR REPLACE VIEW hub_editorial_content_queue AS
SELECT
  ec.id,
  ec.identifier,
  ec.title,
  ec.status,
  ec.urgency,
  ec.editorial_priority,
  ec.content_type,
  ct.label AS content_type_label,
  ec.primary_category,
  cat.label AS primary_category_label,
  ec.ai_generated,
  ec.review_due_at,
  ec.date_created,
  ec.date_updated,
  count(DISTINCT ecd.id) FILTER (WHERE ecd.decision='publish') AS channels_recommended,
  count(DISTINCT d.id) AS distributions_created
FROM editorial_contents ec
LEFT JOIN taxonomy_terms ct ON ct.id=ec.content_type
LEFT JOIN taxonomy_terms cat ON cat.id=ec.primary_category
LEFT JOIN editorial_channel_decisions ecd ON ecd.content=ec.id
LEFT JOIN distributions d ON d.content_collection='editorial_contents' AND d.content_id=ec.id
GROUP BY ec.id,ct.label,cat.label;

CREATE OR REPLACE VIEW hub_social_calendar AS
SELECT
  d.id AS distribution_id,
  d.content_collection,
  d.content_id,
  c.key AS channel_key,
  c.name AS channel_name,
  d.editorial_state,
  d.status AS delivery_status,
  d.format,
  d.headline,
  d.publish_from,
  d.publish_until,
  d.published_at,
  d.ai_generated,
  d.approved_by,
  d.approved_at,
  CASE
    WHEN d.content_collection='editorial_contents' THEN ec.title
    WHEN d.content_collection='events' THEN e.title
    ELSE NULL
  END AS content_title
FROM distributions d
JOIN channels c ON c.id=d.channel
LEFT JOIN editorial_contents ec
  ON d.content_collection='editorial_contents' AND ec.id=d.content_id
LEFT JOIN events e
  ON d.content_collection='events' AND e.id=d.content_id
WHERE c.key IN ('instagram','facebook');

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
  (SELECT count(*) FROM editorial_contents WHERE status='draft') AS contents_draft,
  (SELECT count(*) FROM editorial_contents WHERE status='review') AS contents_in_review,
  (SELECT count(*) FROM editorial_contents WHERE urgency IN ('urgent','emergency') AND status NOT IN ('published','archived','cancelled')) AS contents_urgent,
  (SELECT count(*) FROM hub_social_calendar WHERE channel_key='instagram' AND editorial_state IN ('approved','scheduled') AND publish_from >= now()) AS instagram_upcoming,
  (SELECT count(*) FROM hub_social_calendar WHERE channel_key='facebook' AND editorial_state IN ('approved','scheduled') AND publish_from >= now()) AS facebook_upcoming,
  (SELECT count(*) FROM editorial_channel_decisions WHERE decision='hold') AS routing_holds,
  now() AS generated_at;

INSERT INTO hub_schema_migrations(version)
VALUES ('0.4.0-ai-social-editorial')
ON CONFLICT (version) DO NOTHING;

COMMIT;
