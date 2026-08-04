-- Roncegno Content Hub 0.1 — core schema

CREATE TYPE editorial_status AS ENUM ('draft','review','approved','scheduled','published','cancelled','archived');
CREATE TYPE distribution_status AS ENUM ('disabled','pending','scheduled','active','expired','error');
CREATE TYPE territorial_level AS ENUM ('valley','village','farms','mountain');
CREATE TYPE schedule_type AS ENUM ('single','multiple','recurring');
CREATE TYPE channel_type AS ENUM ('website','screen','api','external');

CREATE TABLE taxonomies (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  key varchar(80) NOT NULL UNIQUE,
  name varchar(160) NOT NULL,
  description text,
  multiple boolean NOT NULL DEFAULT true,
  public boolean NOT NULL DEFAULT true,
  sort integer NOT NULL DEFAULT 0,
  date_created timestamptz NOT NULL DEFAULT now(),
  date_updated timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE taxonomy_terms (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  taxonomy uuid NOT NULL REFERENCES taxonomies(id) ON DELETE CASCADE,
  key varchar(100) NOT NULL,
  label varchar(160) NOT NULL,
  description text,
  icon varchar(80),
  color_token varchar(80),
  sort integer NOT NULL DEFAULT 0,
  active boolean NOT NULL DEFAULT true,
  external_code varchar(160),
  date_created timestamptz NOT NULL DEFAULT now(),
  date_updated timestamptz NOT NULL DEFAULT now(),
  UNIQUE(taxonomy, key)
);

CREATE TABLE channels (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  key varchar(100) NOT NULL UNIQUE,
  name varchar(160) NOT NULL,
  channel_type channel_type NOT NULL,
  description text,
  active boolean NOT NULL DEFAULT true,
  configuration jsonb NOT NULL DEFAULT '{}'::jsonb,
  sort integer NOT NULL DEFAULT 0,
  date_created timestamptz NOT NULL DEFAULT now(),
  date_updated timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE organizations (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  status editorial_status NOT NULL DEFAULT 'draft',
  identifier varchar(120) NOT NULL UNIQUE,
  slug varchar(180) NOT NULL UNIQUE,
  name varchar(240) NOT NULL,
  short_name varchar(120),
  organization_type uuid REFERENCES taxonomy_terms(id) ON DELETE SET NULL,
  description text,
  logo uuid,
  cover_image uuid,
  email varchar(240),
  phone varchar(80),
  website_url text,
  facebook_url text,
  instagram_url text,
  address text,
  location geometry(Point, 4326),
  contact_person varchar(180),
  public_profile boolean NOT NULL DEFAULT true,
  owner_user uuid,
  date_created timestamptz NOT NULL DEFAULT now(),
  date_updated timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE places (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  status editorial_status NOT NULL DEFAULT 'draft',
  identifier varchar(120) NOT NULL UNIQUE,
  slug varchar(180) NOT NULL UNIQUE,
  name varchar(240) NOT NULL,
  short_description text NOT NULL,
  description text,
  place_type uuid REFERENCES taxonomy_terms(id) ON DELETE SET NULL,
  locality uuid REFERENCES taxonomy_terms(id) ON DELETE SET NULL,
  address text,
  location geometry(Point, 4326),
  altitude integer,
  territorial_level territorial_level,
  boundary geometry(Polygon, 4326),
  opening_hours jsonb NOT NULL DEFAULT '{}'::jsonb,
  access_notes text,
  visit_duration_minutes integer,
  website_url text,
  phone varchar(80),
  email varchar(240),
  booking_url text,
  parking_notes text,
  public_transport_notes text,
  cover_image uuid,
  video_url text,
  image_alt text,
  image_credits text,
  managing_organization uuid REFERENCES organizations(id) ON DELETE SET NULL,
  date_created timestamptz NOT NULL DEFAULT now(),
  date_updated timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE organizations ADD COLUMN place uuid REFERENCES places(id) ON DELETE SET NULL;

CREATE TABLE events (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  status editorial_status NOT NULL DEFAULT 'draft',
  identifier varchar(120) NOT NULL UNIQUE,
  slug varchar(180) NOT NULL UNIQUE,
  title varchar(300) NOT NULL,
  short_title varchar(100),
  abstract text NOT NULL,
  description text NOT NULL,
  keywords text,
  reading_time integer,
  schedule_type schedule_type NOT NULL DEFAULT 'single',
  start_datetime timestamptz NOT NULL,
  end_datetime timestamptz,
  all_day boolean NOT NULL DEFAULT false,
  timezone varchar(80) NOT NULL DEFAULT 'Europe/Rome',
  recurrence_rule text,
  parent_event uuid REFERENCES events(id) ON DELETE SET NULL,
  booking_deadline timestamptz,
  cancelled_reason text,
  place uuid REFERENCES places(id) ON DELETE SET NULL,
  address_override text,
  location geometry(Point, 4326),
  online_event boolean NOT NULL DEFAULT false,
  online_url text,
  is_free boolean NOT NULL DEFAULT true,
  cost_notes text,
  booking_required boolean NOT NULL DEFAULT false,
  booking_url text,
  maximum_capacity integer,
  accessibility_notes text,
  contact_organization uuid REFERENCES organizations(id) ON DELETE SET NULL,
  contact_name varchar(180),
  contact_email varchar(240),
  contact_phone varchar(80),
  contact_url text,
  additional_information text,
  cover_image uuid,
  poster uuid,
  video_url text,
  image_alt text,
  image_credits text,
  featured boolean NOT NULL DEFAULT false,
  editorial_priority integer NOT NULL DEFAULT 0,
  source varchar(160),
  source_url text,
  external_identifier varchar(180),
  date_created timestamptz NOT NULL DEFAULT now(),
  date_updated timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT event_dates_valid CHECK (end_datetime IS NULL OR end_datetime >= start_datetime),
  CONSTRAINT event_cancel_reason CHECK (status <> 'cancelled' OR cancelled_reason IS NOT NULL),
  CONSTRAINT event_cost_notes CHECK (is_free OR cost_notes IS NOT NULL),
  CONSTRAINT event_online_url CHECK (NOT online_event OR online_url IS NOT NULL)
);

CREATE TABLE event_occurrences (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  event uuid NOT NULL REFERENCES events(id) ON DELETE CASCADE,
  start_datetime timestamptz NOT NULL,
  end_datetime timestamptz,
  all_day boolean NOT NULL DEFAULT false,
  status editorial_status NOT NULL DEFAULT 'published',
  place_override uuid REFERENCES places(id) ON DELETE SET NULL,
  location_override geometry(Point, 4326),
  notes text,
  date_created timestamptz NOT NULL DEFAULT now(),
  date_updated timestamptz NOT NULL DEFAULT now(),
  UNIQUE(event, start_datetime),
  CONSTRAINT occurrence_dates_valid CHECK (end_datetime IS NULL OR end_datetime >= start_datetime)
);

CREATE TABLE distributions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  channel uuid NOT NULL REFERENCES channels(id) ON DELETE CASCADE,
  content_collection varchar(100) NOT NULL,
  content_id uuid NOT NULL,
  enabled boolean NOT NULL DEFAULT true,
  publish_from timestamptz,
  publish_until timestamptz,
  priority integer NOT NULL DEFAULT 0,
  status distribution_status NOT NULL DEFAULT 'pending',
  last_published_at timestamptz,
  external_id varchar(180),
  external_uri text,
  last_error text,
  configuration jsonb NOT NULL DEFAULT '{}'::jsonb,
  date_created timestamptz NOT NULL DEFAULT now(),
  date_updated timestamptz NOT NULL DEFAULT now(),
  UNIQUE(channel, content_collection, content_id),
  CONSTRAINT distribution_dates_valid CHECK (publish_until IS NULL OR publish_from IS NULL OR publish_until >= publish_from)
);

CREATE TABLE screens (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  key varchar(100) NOT NULL UNIQUE,
  name varchar(180) NOT NULL,
  location_name varchar(240),
  orientation varchar(20) NOT NULL DEFAULT 'landscape',
  resolution_width integer NOT NULL DEFAULT 1920,
  resolution_height integer NOT NULL DEFAULT 1080,
  active boolean NOT NULL DEFAULT true,
  refresh_seconds integer NOT NULL DEFAULT 60,
  last_seen_at timestamptz,
  date_created timestamptz NOT NULL DEFAULT now(),
  date_updated timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT screen_orientation CHECK (orientation IN ('landscape','portrait'))
);

CREATE TABLE playlists (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name varchar(180) NOT NULL,
  status editorial_status NOT NULL DEFAULT 'draft',
  valid_from timestamptz,
  valid_until timestamptz,
  fallback_playlist uuid REFERENCES playlists(id) ON DELETE SET NULL,
  date_created timestamptz NOT NULL DEFAULT now(),
  date_updated timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE screens ADD COLUMN default_playlist uuid REFERENCES playlists(id) ON DELETE SET NULL;

CREATE TABLE screen_overrides (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  distribution uuid NOT NULL UNIQUE REFERENCES distributions(id) ON DELETE CASCADE,
  short_title varchar(100),
  short_text text,
  image uuid,
  layout varchar(80) NOT NULL DEFAULT 'automatic',
  duration_seconds integer NOT NULL DEFAULT 12,
  show_qr_code boolean NOT NULL DEFAULT true,
  qr_target_url text,
  background_style varchar(80),
  call_to_action varchar(120),
  date_created timestamptz NOT NULL DEFAULT now(),
  date_updated timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE playlist_items (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  playlist uuid NOT NULL REFERENCES playlists(id) ON DELETE CASCADE,
  distribution uuid NOT NULL REFERENCES distributions(id) ON DELETE CASCADE,
  sort integer NOT NULL DEFAULT 0,
  duration_override integer,
  UNIQUE(playlist, distribution)
);

-- Generic junctions for terms and organizations
CREATE TABLE events_taxonomy_terms (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  event uuid NOT NULL REFERENCES events(id) ON DELETE CASCADE,
  term uuid NOT NULL REFERENCES taxonomy_terms(id) ON DELETE CASCADE,
  relation_type varchar(60) NOT NULL,
  sort integer NOT NULL DEFAULT 0,
  UNIQUE(event, term, relation_type)
);

CREATE TABLE places_taxonomy_terms (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  place uuid NOT NULL REFERENCES places(id) ON DELETE CASCADE,
  term uuid NOT NULL REFERENCES taxonomy_terms(id) ON DELETE CASCADE,
  relation_type varchar(60) NOT NULL,
  sort integer NOT NULL DEFAULT 0,
  UNIQUE(place, term, relation_type)
);

CREATE TABLE events_organizations (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  event uuid NOT NULL REFERENCES events(id) ON DELETE CASCADE,
  organization uuid NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  relation_type varchar(60) NOT NULL,
  sort integer NOT NULL DEFAULT 0,
  UNIQUE(event, organization, relation_type)
);

CREATE TABLE places_nearby_places (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  place uuid NOT NULL REFERENCES places(id) ON DELETE CASCADE,
  related_place uuid NOT NULL REFERENCES places(id) ON DELETE CASCADE,
  sort integer NOT NULL DEFAULT 0,
  UNIQUE(place, related_place),
  CONSTRAINT no_self_nearby CHECK (place <> related_place)
);

-- Directus file relations are kept as UUIDs and can be linked to directus_files after bootstrap.
CREATE TABLE events_files (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  event uuid NOT NULL REFERENCES events(id) ON DELETE CASCADE,
  file uuid NOT NULL,
  relation_type varchar(40) NOT NULL,
  sort integer NOT NULL DEFAULT 0,
  UNIQUE(event, file, relation_type)
);

CREATE TABLE places_files (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  place uuid NOT NULL REFERENCES places(id) ON DELETE CASCADE,
  file uuid NOT NULL,
  relation_type varchar(40) NOT NULL,
  sort integer NOT NULL DEFAULT 0,
  UNIQUE(place, file, relation_type)
);

-- Useful indexes
CREATE INDEX idx_terms_taxonomy ON taxonomy_terms(taxonomy);
CREATE INDEX idx_events_status ON events(status);
CREATE INDEX idx_events_start ON events(start_datetime);
CREATE INDEX idx_events_place ON events(place);
CREATE INDEX idx_occurrences_start ON event_occurrences(start_datetime);
CREATE INDEX idx_occurrences_status ON event_occurrences(status);
CREATE INDEX idx_distributions_channel_status ON distributions(channel, status);
CREATE INDEX idx_distributions_window ON distributions(publish_from, publish_until);
CREATE INDEX idx_places_level ON places(territorial_level);
CREATE INDEX idx_places_location_gist ON places USING GIST(location);
CREATE INDEX idx_places_boundary_gist ON places USING GIST(boundary);
CREATE INDEX idx_events_location_gist ON events USING GIST(location);
CREATE INDEX idx_occurrences_location_gist ON event_occurrences USING GIST(location_override);

-- Automatic date_updated maintenance
CREATE OR REPLACE FUNCTION set_date_updated() RETURNS trigger AS $$
BEGIN
  NEW.date_updated = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DO $$
DECLARE t text;
BEGIN
  FOREACH t IN ARRAY ARRAY['taxonomies','taxonomy_terms','channels','organizations','places','events','event_occurrences','distributions','screens','playlists','screen_overrides']
  LOOP
    EXECUTE format('CREATE TRIGGER %I_date_updated BEFORE UPDATE ON %I FOR EACH ROW EXECUTE FUNCTION set_date_updated()', t, t);
  END LOOP;
END $$;
