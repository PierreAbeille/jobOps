-- Unicité souple entreprises
CREATE UNIQUE INDEX IF NOT EXISTS companies_name_website_uniq
  ON companies ( lower(name), COALESCE(lower(website), '') );

-- Unicité case-insensitive skills
CREATE UNIQUE INDEX IF NOT EXISTS skills_lower_name_uniq
  ON skills ( lower(name) );

-- Offres: perfs analytiques
CREATE INDEX IF NOT EXISTS offers_posted_idx    ON offers (posted_at);
CREATE INDEX IF NOT EXISTS offers_ingested_idx  ON offers (ingested_at);
CREATE INDEX IF NOT EXISTS offers_status_idx    ON offers (status);
CREATE INDEX IF NOT EXISTS offers_tags_gin      ON offers USING GIN (tags);

-- Raw docs
CREATE INDEX IF NOT EXISTS raw_documents_url_idx ON raw_documents (url);

-- Threads/Interactions
CREATE INDEX IF NOT EXISTS threads_status_idx      ON threads (status);
CREATE INDEX IF NOT EXISTS threads_next_action_idx ON threads (next_action_at);
CREATE INDEX IF NOT EXISTS threads_type_idx        ON threads (thread_type);
CREATE INDEX IF NOT EXISTS interactions_thread_time_idx
  ON interactions (thread_id, happened_at);

-- Contacts
CREATE INDEX IF NOT EXISTS contacts_phone_e164_idx ON contacts (phone_e164);

-- Offer_contacts
CREATE INDEX IF NOT EXISTS offer_contacts_contact_idx ON offer_contacts (contact_id);
CREATE INDEX IF NOT EXISTS offer_contacts_role_idx    ON offer_contacts (role);

-- market_pulses unicité (day, market, region?, country?)
CREATE UNIQUE INDEX IF NOT EXISTS market_pulses_uniq
  ON market_pulses (
    day, market,
    COALESCE(region, '__ANY__'),
    COALESCE(country, '__ANY__')
  );