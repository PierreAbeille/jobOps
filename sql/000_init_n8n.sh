#!/bin/sh
set -e

# Passe le mot de passe à psql via variable -v
# Le shell NE doit PAS développer le SQL, d'où les heredocs quotés.

# Crée l'utilisateur n8n si absent
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" -v n8npwd="${N8N_DB_PASSWORD}" <<'SQL'
SELECT format('CREATE USER n8n WITH PASSWORD %L', :'n8npwd')
WHERE NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'n8n')
\gexec
SQL

# Crée la base n8n si absente et en donne la propriété
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" <<'SQL'
SELECT 'CREATE DATABASE n8n OWNER n8n'
WHERE NOT EXISTS (SELECT 1 FROM pg_database WHERE datname = 'n8n')
\gexec
SQL

# Ajuste le schéma public
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname n8n <<'SQL'
ALTER SCHEMA public OWNER TO n8n;
GRANT ALL PRIVILEGES ON SCHEMA public TO n8n;
SQL