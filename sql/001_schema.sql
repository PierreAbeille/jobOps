-- =========================================================
-- JobOps — Schéma v2.2 (pragmatique)
-- Enums gérés en table, FK composites via colonnes générées
-- Téléphone simple + phone_e164; tags en TEXT[]
-- =========================================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";  -- optionnel, pas utilisé ici mais utile si besoin

-- 0) Table d'enums globale (clé composite)
CREATE TABLE IF NOT EXISTS enum_values (
  category    TEXT NOT NULL,
  code        TEXT NOT NULL,
  label       TEXT NOT NULL,
  sort_order  INT  DEFAULT 0,
  is_active   BOOLEAN DEFAULT TRUE,
  created_at  TIMESTAMPTZ DEFAULT now(),
  updated_at  TIMESTAMPTZ DEFAULT now(),
  PRIMARY KEY (category, code)
);

-- 1) Sources et messages source (mail/rss/api)
CREATE TABLE IF NOT EXISTS sources (
  id          BIGSERIAL PRIMARY KEY,
  kind        TEXT NOT NULL,       -- 'email' | 'rss' | 'api' | 'manual'
  name        TEXT NOT NULL,
  details     JSONB,
  created_at  TIMESTAMPTZ DEFAULT now(),
  updated_at  TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS source_messages (
  id            BIGSERIAL PRIMARY KEY,
  source_id     BIGINT REFERENCES sources(id) ON DELETE CASCADE,
  external_id   TEXT NOT NULL,
  subject       TEXT,
  received_at   TIMESTAMPTZ,
  payload       JSONB,
  created_at    TIMESTAMPTZ DEFAULT now(),
  UNIQUE (source_id, external_id)
);

-- 2) Documents bruts (HTML/TXT) issus d'un mail/rss ou d'un fetch
CREATE TABLE IF NOT EXISTS raw_documents (
  id                   BIGSERIAL PRIMARY KEY,
  source_message_id    BIGINT REFERENCES source_messages(id) ON DELETE SET NULL,
  url                  TEXT,
  fetched_at           TIMESTAMPTZ DEFAULT now(),
  content_html         TEXT,
  content_text         TEXT,
  http_meta            JSONB
);

-- 3) Référentiel entreprises/contacts
CREATE TABLE IF NOT EXISTS companies (
  id           BIGSERIAL PRIMARY KEY,
  name         TEXT NOT NULL,
  website      TEXT,
  linkedin_url TEXT,
  country      TEXT,
  created_at   TIMESTAMPTZ DEFAULT now(),
  updated_at   TIMESTAMPTZ DEFAULT now()
);
-- Unicité souple sur (lower(name), lower(website)) via index dans 002_indexes.sql

CREATE TABLE IF NOT EXISTS contacts (
  id           BIGSERIAL PRIMARY KEY,
  company_id   BIGINT REFERENCES companies(id) ON DELETE SET NULL,
  full_name    TEXT,
  email        TEXT UNIQUE,           -- mono-email pragmatique
  phone        TEXT,
  phone_e164   TEXT,
  role         TEXT,                  -- libre (tu peux l’aligner sur enum_values plus tard)
  linkedin_url TEXT,
  notes        TEXT,
  created_at   TIMESTAMPTZ DEFAULT now(),
  updated_at   TIMESTAMPTZ DEFAULT now()
);

-- 4) Compétences
CREATE TABLE IF NOT EXISTS skills (
  id         BIGSERIAL PRIMARY KEY,
  name       TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now()
);
-- Unicité case-insensitive via index dans 002_indexes.sql

-- 5) Offres
CREATE TABLE IF NOT EXISTS offers (
  id                 BIGSERIAL PRIMARY KEY,
  company_id         BIGINT REFERENCES companies(id) ON DELETE SET NULL,

  title              TEXT NOT NULL,
  location           TEXT,

  -- remote_type avec contrôle enum_values via FK composite
  remote_type        TEXT NOT NULL,
  remote_type_cat    TEXT GENERATED ALWAYS AS ('remote_type') STORED,
  -- FK composite vers enum_values(category, code)
  CONSTRAINT offers_remote_type_fk
    FOREIGN KEY (remote_type_cat, remote_type)
    REFERENCES enum_values(category, code),

  -- contract_type contrôlé via enum_values (nullable)
  contract_type      TEXT,
  contract_type_cat  TEXT GENERATED ALWAYS AS ('contract_type') STORED,
  CONSTRAINT offers_contract_type_fk
    FOREIGN KEY (contract_type_cat, contract_type)
    REFERENCES enum_values(category, code),

  url                TEXT UNIQUE,
  source             TEXT,             -- 'linkedin' | 'freework' | ...
  source_ref         TEXT,

  currency           TEXT DEFAULT 'EUR',
  salary_min         NUMERIC,
  salary_max         NUMERIC,
  daily_rate_min     NUMERIC,
  daily_rate_max     NUMERIC,

  posted_at          TIMESTAMPTZ,
  ingested_at        TIMESTAMPTZ DEFAULT now(),
  scraped_doc_id     BIGINT REFERENCES raw_documents(id) ON DELETE SET NULL,

  status             TEXT,             -- laissé libre ici (tu peux aussi l’enum-ifier)

  hash               TEXT UNIQUE,
  tags               TEXT[] DEFAULT '{}',
  notes              TEXT,

  primary_contact_id BIGINT REFERENCES contacts(id) ON DELETE SET NULL
);

-- 6) Lien offre ↔ skill
CREATE TABLE IF NOT EXISTS offer_skills (
  offer_id  BIGINT REFERENCES offers(id)  ON DELETE CASCADE,
  skill_id  BIGINT REFERENCES skills(id)  ON DELETE CASCADE,
  weight    SMALLINT DEFAULT 1,
  PRIMARY KEY (offer_id, skill_id)
);

-- 7) Lien offre ↔ contacts (N-N) avec rôle et provenance
CREATE TABLE IF NOT EXISTS offer_contacts (
  offer_id       BIGINT REFERENCES offers(id)   ON DELETE CASCADE,
  contact_id     BIGINT REFERENCES contacts(id) ON DELETE CASCADE,

  role           TEXT NOT NULL,
  role_cat       TEXT GENERATED ALWAYS AS ('offer_contact_role') STORED,
  CONSTRAINT offer_contacts_role_fk
    FOREIGN KEY (role_cat, role)
    REFERENCES enum_values(category, code),

  discovered_via TEXT,                 -- 'llm' | 'scrape' | 'linkedin' | 'hunter' | 'manual'
  confidence     SMALLINT,             -- 0..100
  notes          TEXT,
  created_at     TIMESTAMPTZ DEFAULT now(),
  PRIMARY KEY (offer_id, contact_id, role)
);

-- 8) Threads CRM unifiés (application/outreach)
CREATE TABLE IF NOT EXISTS threads (
  id             BIGSERIAL PRIMARY KEY,

  thread_type    TEXT NOT NULL,
  thread_type_cat TEXT GENERATED ALWAYS AS ('thread_type') STORED,
  CONSTRAINT threads_type_fk
    FOREIGN KEY (thread_type_cat, thread_type)
    REFERENCES enum_values(category, code),

  company_id     BIGINT REFERENCES companies(id) ON DELETE SET NULL,
  offer_id       BIGINT REFERENCES offers(id)    ON DELETE SET NULL,
  contact_id     BIGINT REFERENCES contacts(id)  ON DELETE SET NULL,

  channel        TEXT,
  channel_cat    TEXT GENERATED ALWAYS AS ('channel') STORED,
  CONSTRAINT threads_channel_fk
    FOREIGN KEY (channel_cat, channel)
    REFERENCES enum_values(category, code),

  status         TEXT,
  status_cat     TEXT GENERATED ALWAYS AS ('thread_status') STORED,
  CONSTRAINT threads_status_fk
    FOREIGN KEY (status_cat, status)
    REFERENCES enum_values(category, code),

  started_at     TIMESTAMPTZ DEFAULT now(),
  last_action_at TIMESTAMPTZ,
  next_action_at TIMESTAMPTZ,
  relance_count  INT DEFAULT 0,
  notes          TEXT,

  -- Règle métier: une application doit viser une offre
  CONSTRAINT threads_application_requires_offer
    CHECK ( (thread_type = 'application' AND offer_id IS NOT NULL)
            OR thread_type = 'outreach' )
);

-- 9) Interactions (historique des échanges)
CREATE TABLE IF NOT EXISTS interactions (
  id          BIGSERIAL PRIMARY KEY,
  thread_id   BIGINT REFERENCES threads(id) ON DELETE CASCADE,
  happened_at TIMESTAMPTZ DEFAULT now(),

  kind        TEXT,
  kind_cat    TEXT GENERATED ALWAYS AS ('interaction_kind') STORED,
  CONSTRAINT interactions_kind_fk
    FOREIGN KEY (kind_cat, kind)
    REFERENCES enum_values(category, code),

  direction   TEXT,
  direction_cat TEXT GENERATED ALWAYS AS ('direction') STORED,
  CONSTRAINT interactions_direction_fk
    FOREIGN KEY (direction_cat, direction)
    REFERENCES enum_values(category, code),

  summary     TEXT,
  payload     JSONB
);

-- 10) Suivi “pulses” marché (multi-région/pays facultatif)
CREATE TABLE IF NOT EXISTS market_pulses (
  id             BIGSERIAL PRIMARY KEY,
  day            DATE NOT NULL,
  market         TEXT NOT NULL,      -- 'Angular' | 'React' | ...
  region         TEXT,
  country        TEXT,
  mission_count  INTEGER NOT NULL CHECK (mission_count >= 0),
  notes          TEXT,
  created_at     TIMESTAMPTZ DEFAULT now()
);
-- Unicité gérée dans 002_indexes.sql (avec COALESCE)

-- 11) Analyse LLM (extraction/score)
CREATE TABLE IF NOT EXISTS offer_analysis (
  id          BIGSERIAL PRIMARY KEY,
  offer_id    BIGINT UNIQUE REFERENCES offers(id) ON DELETE CASCADE,
  extracted   JSONB,
  fit_score   SMALLINT,
  reasoning   TEXT,
  created_at  TIMESTAMPTZ DEFAULT now()
);