# pgVectorScaleDB

PostgreSQL 18 on top of `timescale/timescaledb:latest-pg18`, with these extensions compiled in and created on first start:

- [TimescaleDB](https://github.com/timescale/timescaledb)
- [pgvector](https://github.com/pgvector/pgvector)
- [pgvectorscale](https://github.com/timescale/pgvectorscale)
- [system_stats](https://github.com/EnterpriseDB/system_stats)

[PostgresML](https://github.com/postgresml/postgresml) is installed by the same build once a release supports PostgreSQL 18. The latest release stops at PostgreSQL 17, so it is skipped for now.

A daily workflow tracks the latest upstream extension releases and publishes a new image. Images are built for `linux/amd64` and `linux/arm64`.

- Source: https://github.com/charlestephen/pgVectorScaleDB
- Issues: https://github.com/charlestephen/pgVectorScaleDB/issues
- Also published at `ghcr.io/charlestephen/pgvectorscaledb`

## Tags

| Tag | Meaning |
|---|---|
| `pg18` | Latest build on PostgreSQL 18. |
| `latest` | Same as `pg18`. |

Both tags move whenever the image is rebuilt, which can include new extension versions. For a deployment you don't want to change under you, pin by digest (`charlestephen/pgvectorscaledb@sha256:...`).

## Quick start

```bash
docker run -d --name pgvectorscaledb --restart unless-stopped \
  -e POSTGRES_PASSWORD='replace-with-a-strong-password' \
  -p 5432:5432 \
  -v pgdata:/var/lib/postgresql \
  charlestephen/pgvectorscaledb:pg18
```

Replace the password with your own. The data lives under `/var/lib/postgresql` (`PGDATA` is `/var/lib/postgresql/18/docker`), so mount the volume there.

Connect with `psql`:

```bash
docker exec -it pgvectorscaledb psql -U postgres
```

On the first start, the image creates the `timescaledb`, `vector`, `vectorscale` and `system_stats` extensions in the database named by `POSTGRES_DB` (default `postgres`). If you run `docker run` again with an existing data volume, the init scripts are skipped. To add the extensions to another database, run:

```sql
CREATE EXTENSION IF NOT EXISTS timescaledb;
CREATE EXTENSION IF NOT EXISTS vector;
CREATE EXTENSION IF NOT EXISTS vectorscale;
CREATE EXTENSION IF NOT EXISTS system_stats;
```

Check what is installed:

```sql
SELECT extname, extversion FROM pg_extension ORDER BY 1;
```

### Docker Compose

```yaml
services:
  postgres:
    image: charlestephen/pgvectorscaledb:pg18
    restart: unless-stopped
    environment:
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD:?set POSTGRES_PASSWORD}
      POSTGRES_DB: app
    ports:
      - "5432:5432"
    volumes:
      - pgdata:/var/lib/postgresql

volumes:
  pgdata:
```

```bash
export POSTGRES_PASSWORD='replace-with-a-strong-password'
docker compose up -d
```

To update:

```bash
docker compose pull && docker compose up -d
```

## Example

```sql
CREATE TABLE items (id bigserial PRIMARY KEY, embedding vector(3));
INSERT INTO items (embedding) VALUES ('[1,2,3]'), ('[4,5,6]');
SELECT id FROM items ORDER BY embedding <-> '[3,1,2]' LIMIT 5;
```

pgvectorscale adds a disk-friendly index for larger vector sets:

```sql
CREATE INDEX ON items USING diskann (embedding);
```

## Configuration

This image uses the standard PostgreSQL image environment variables, such as `POSTGRES_PASSWORD`, `POSTGRES_USER`, `POSTGRES_DB` and `POSTGRES_INITDB_ARGS`. `POSTGRES_PASSWORD` is required. Extra scripts mounted into `/docker-entrypoint-initdb.d/` run on first start, after the extension setup.

TimescaleDB is loaded through `shared_preload_libraries`. To change PostgreSQL settings, pass them as `-c` flags, for example:

```bash
docker run -d --name pgvectorscaledb -e POSTGRES_PASSWORD='replace-me' \
  -v pgdata:/var/lib/postgresql charlestephen/pgvectorscaledb:pg18 \
  -c shared_buffers=1GB -c max_connections=200
```

`timescaledb` stays in `shared_preload_libraries` when you pass `-c` flags.

## Upgrading

A PostgreSQL major version change needs a dump and restore or `pg_upgrade`. Updating the image within `pg18` keeps the same data format. After a new image brings newer extension versions, run `ALTER EXTENSION <name> UPDATE;` in each database to move them to the new version.

## License

The build files and scripts are licensed under the GNU General Public License v3.0 (https://github.com/charlestephen/pgVectorScaleDB/blob/main/LICENSE). The software included in the image is distributed under its own licenses.
