-- Vue matérialisée "flat" pour Metabase (1 ligne = 1 offre)
DROP MATERIALIZED VIEW IF EXISTS v_offers_enriched;

CREATE MATERIALIZED VIEW v_offers_enriched AS
SELECT
  o.id                  AS offer_id,
  o.title               AS offer_title,
  o.url                 AS offer_url,
  o.posted_at           AS offer_posted_at,
  o.ingested_at         AS offer_ingested_at,

  o.location,
  o.remote_type,
  o.contract_type,
  o.currency,
  o.salary_min, o.salary_max,
  o.daily_rate_min, o.daily_rate_max,
  o.tags,
  o.status,

  c.id                  AS company_id,
  c.name                AS company_name,
  c.website             AS company_website,
  c.country             AS company_country,

  pc.id                 AS primary_contact_id,
  pc.full_name          AS pc_full_name,
  pc.email              AS pc_email,
  pc.phone_e164         AS pc_phone_e164,
  pc.role               AS pc_role,
  pc.linkedin_url       AS pc_linkedin,

  oa.fit_score          AS analysis_fit_score,
  oa.extracted          AS analysis_extracted,
  oa.reasoning          AS analysis_reasoning

FROM offers o
LEFT JOIN companies c        ON c.id  = o.company_id
LEFT JOIN contacts  pc       ON pc.id = o.primary_contact_id
LEFT JOIN offer_analysis oa  ON oa.offer_id = o.id
WITH NO DATA;

-- Premier remplissage (obligatoirement non-concurrent la première fois)
REFRESH MATERIALIZED VIEW v_offers_enriched;

-- Puis création de l'index unique pour les refresh concurrents suivants
CREATE UNIQUE INDEX v_offers_enriched_offer_id_uidx
  ON v_offers_enriched(offer_id);