#!/bin/sh
# Runs on first init, after TimescaleDB's own scripts.
set -eu

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<'SQL'
CREATE EXTENSION IF NOT EXISTS vector;
CREATE EXTENSION IF NOT EXISTS vectorscale;
CREATE EXTENSION IF NOT EXISTS system_stats;
SQL

if psql -tA --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" \
  -c "SELECT 1 FROM pg_available_extensions WHERE name = 'pgml'" | grep -q 1; then
  psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" \
    -c "CREATE EXTENSION IF NOT EXISTS pgml;"
fi
