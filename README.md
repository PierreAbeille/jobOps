# JobOps — Pipeline d’intel marché & prospection freelance (self-host)

**Ce que c’est.**  
JobOps automatise la veille marché (emails/RSS/APIs), normalise les offres, extrait les infos clés (LLM), et fournit un mini-CRM de prospection avec dashboards en temps réel. Le tout, **self-host** en Docker Compose: Postgres + n8n + Metabase.

**Ce que ça prouve.**  
Architecture data propre (schéma SQL, vues matérialisées, index), automatisation low-code orchestrée, intégrations OAuth/IMAP, prompts LLM robustes, visualisation orientée décision. Bref: **autonomie, adaptabilité, sens produit**.

---

## Highlights

- **Ingestion multi-sources**: Gmail (OAuth2 ou IMAP), RSS, APIs.
- **Parsing LLM**: extraction stricte JSON (titre, TJM, remote, skills, contact), déduplication par hash.
- **Schéma SQL pragmatique**: `offers`, `companies`, `contacts`, `threads` (mini-CRM), `interactions`, `skills`, `offer_analysis`, `market_pulses`, enums centralisés.
- **Vue matérialisée `v_offers_enriched`**: explorations rapides dans Metabase.
- **Dashboard**: tendances stack, funnel candidatures, TJM par source.
- **Sobriété**: ressources plafonnées, 0 cloud managé, 100% Compose.

---

## Architecture (vue simple)
```
Browser ──> n8n (http://localhost:5678)
│   ├─ Gmail / RSS / HTTP fetch
│   ├─ OpenAI (extraction JSON)
│   └─ Postgres (insert/upsert + refresh MV)
Browser ──> Metabase (http://localhost:3000)
Postgres (5432) ← schema JobOps + DB interne n8n
```
---

## Démarrage rapide

1. **Prérequis**
   - Docker + Docker Compose
   - Ports libres: 5678 (n8n), 3000 (Metabase)

2. **Config**
   - Copier `.env.example` en `.env` et renseigner:
     - `POSTGRES_PASSWORD`, `DB_POSTGRESDB_PASSWORD` (user interne n8n)
     - `N8N_ENCRYPTION_KEY` (clé hex 64)  
   - Les scripts SQL sont déjà dans `./sql`.

3. **Lancer**
   ```bash
   docker compose up -d
   docker compose ps

4.	**Onboarding**
  - n8n: http://localhost:5678 → créer le compte Owner
  - Credentials:
  - Postgres — JobOps RW: host postgres, port 5432, db jobops
  - Gmail: OAuth2 (scopes minimaux gmail.readonly/gmail.send) ou IMAP/SMTP App Password
  - OpenAI: clé API
  - Metabase: http://localhost:3000 → Admin → Add Database
  - Type PostgreSQL, host postgres, port 5432, db jobops
6.	**Vérifs**
```
docker compose logs postgres --tail=80 | grep "ready to accept"
docker compose exec postgres psql -U ${POSTGRES_USER} -d ${POSTGRES_DB} -c "\dt"
docker compose logs n8n --tail=200 | grep -i postgres || true
```


⸻

### Démo en 3 minutes (optionnel)
1. Seed minimal
    ```
    docker compose exec -T postgres psql -U ${POSTGRES_USER} -d ${POSTGRES_DB} < sql/demo_seed.sql
    docker compose exec postgres psql -U ${POSTGRES_USER} -d ${POSTGRES_DB} -c "REFRESH MATERIALIZED VIEW v_offers_enriched;"
    ```
2. Metabase → Browse data → v_offers_enriched
3. n8n → exécuter un nœud Postgres (SELECT 1) + un nœud Gmail (Get Labels).

⸻

Pourquoi ce projet
- Vision data-driven sur le marché freelance (volumétrie par jour/stack, TJM, remote).
- Accélérer la prospection: contacts rattachés aux offres, relances planifiées, historique.
- Possession des données: Postgres à toi, pas de vendor lock-in.
- Design technique: enums centralisés, FKs, index, vue matérialisée pour l’analytique.

⸻

Roadmap courte
- Enrichissement automatique des contacts (LinkedIn/Hunter-like, si API dispo)
- Scoring de “fit” par stack/expérience
- Relances séquencées J+2/J+7 avec templates
- Pulse hebdo email (Metabase)

⸻

Licence & sécurité
- Secrets dans .env (non commités).
- N8N_ENCRYPTION_KEY stable.
- Postgres non exposé publiquement.

---

# Pourquoi ce projet ?
## Le problème
Le marché freelance bouge vite. Les offres sont éparpillées (emails, portails, RSS). On perd du temps à trier, copier, relancer. Résultat: on passe à côté des bons créneaux.

## Ma solution (JobOps)
Un pipeline local qui:
- **récupère** automatiquement les offres,
- **extrait** les infos utiles (stack, TJM, remote, contact),
- **déduplique** et **structure** dans Postgres,
- **visualise** les tendances,
- **orchestré** par n8n, **piloté** par des prompts LLM robustes,
- avec un **mini-CRM** pour les relances.

## Pourquoi c’est intéressant
- **Livrable concret**: un système reproductible, pas une démo jetable.
- **Compétences mises en jeu**:
  - Data modeling SQL (FK, uniques, enums, vues matérialisées)
  - Orchestration d’intégrations (OAuth/IMAP, HTTP, LLM) via n8n
  - Observabilité simple (Metabase), perfs pragmatiques (index, MV)
  - Docker Compose, self-hosting, sécurité de base (secrets, chiffrement creds n8n)
- **Approche produit**: KPIs orientés marché, UX d’exploration, automatisation des tâches ingrates.

## Architecture (en bref)
- **Postgres**: schéma `offers/companies/contacts/threads/interactions/skills/market_pulses` + `v_offers_enriched`
- **n8n**: ingestion Gmail/RSS/API → HTTP fetch → LLM extraction → upsert DB → refresh MV
- **Metabase**: dashboard (tendances stack, funnel, TJM source)

## Cibles
- Missions front React/Angular, proches du produit.  
- Contextes où l’automatisation et la qualité de données améliorent le delivery.

**Contact**: [Linkedin](https://www.linkedin.com/in/pierre-abeille/)

⸻
# Installation & Ops

## 1) Préparer l’environnement
- Docker + Docker Compose
- `cp .env.example .env` et remplir: `POSTGRES_PASSWORD`, `DB_POSTGRESDB_PASSWORD`, `N8N_ENCRYPTION_KEY`

## 2) Lancer
```bash
docker compose up -d
docker compose ps
```

## 3) Onboarding n8n
- http://localhost:5678 → créer le compte Owner
- Credentials:
  - Postgres — JobOps RW (host postgres, db jobops)
  - Gmail (OAuth2 scopes minimalistes ou IMAP/SMTP App Password)
  - OpenAI (clé)

## 4) Onboarding Metabase
- http://localhost:3000 → Admin → Add Database
- PostgreSQL → host postgres, db jobops

## 5) Vérifications utiles
```
docker compose logs postgres --tail=80 | grep "ready to accept"
docker compose exec postgres psql -U ${POSTGRES_USER} -d ${POSTGRES_DB} -c "SELECT COUNT(*) FROM v_offers_enriched;"
```

## 6) Mises à jour

```docker compose pull && docker compose up -d```

## 7) Reset total

```docker compose down -v --remove-orphans```

---

# 4) `sql/demo_seed.sql` — petites données pour “wow, ça affiche”

```sql
-- Companies
INSERT INTO companies(name, website, country) VALUES
('Acme', 'https://acme.example', 'FR'),
('Globex', 'https://globex.example', 'FR')
ON CONFLICT DO NOTHING;

-- One skill
INSERT INTO skills(name) VALUES ('React') ON CONFLICT DO NOTHING;

-- Offers
WITH c1 AS (SELECT id FROM companies WHERE name='Acme' LIMIT 1),
     c2 AS (SELECT id FROM companies WHERE name='Globex' LIMIT 1)
INSERT INTO offers(company_id, title, location, remote_type, contract_type, currency, daily_rate_min, daily_rate_max, posted_at, source, url, tags)
SELECT id, 'Frontend React', 'Paris', 'remote', 'freelance', 'EUR', 450, 550, now() - interval '1 day', 'email', 'https://jobs.example/acme-frontend', ARRAY['react','typescript']
FROM c1
UNION ALL
SELECT id, 'Angular Dev', 'Lyon', 'hybrid', 'freelance', 'EUR', 400, 500, now(), 'rss', 'https://jobs.example/globex-angular', ARRAY['angular','rxjs']
FROM c2
ON CONFLICT DO NOTHING;

-- Offer skills (juste pour l’exemple)
INSERT INTO offer_skills(offer_id, skill_id, weight)
SELECT o.id, s.id, 1
FROM offers o
JOIN skills s ON lower(s.name)='react'
WHERE o.title ILIKE '%React%'
ON CONFLICT DO NOTHING;
