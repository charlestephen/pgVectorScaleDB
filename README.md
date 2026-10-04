# pgVectorScaleDB

PostgreSQL 18 image based on `timescale/timescaledb:latest-pg18`, with the current releases of [pgvector](https://github.com/pgvector/pgvector), [pgvectorscale](https://github.com/timescale/pgvectorscale), and [system_stats](https://github.com/EnterpriseDB/system_stats) compiled in.

[PostgresML](https://github.com/postgresml/postgresml) is installed by the same build once a release advertises a `pg18` feature. The latest release, 2.10.0, stops at PostgreSQL 17, so `POSTGRESML_TAG=skip` until then. A daily workflow refreshes `versions.env` and publishes new images.

Images:

- `ghcr.io/charlestephen/pgvectorscaledb:pg18`
- `docker.io/charlestephen/pgvectorscaledb:pg18`

```bash
docker run --rm -e POSTGRES_PASSWORD=secret -p 5432:5432 ghcr.io/charlestephen/pgvectorscaledb:pg18
```

The first start creates `timescaledb`, `vector`, `vectorscale`, and `system_stats` in `POSTGRES_DB`.

Docker Hub publishes only after these repository secrets exist:

```bash
gh secret set DOCKERHUB_USERNAME --repo charlestephen/pgVectorScaleDB
gh secret set DOCKERHUB_TOKEN --repo charlestephen/pgVectorScaleDB
```

`DOCKERHUB_TOKEN` is a Docker Hub access token with write access. The Docker Hub account is `charlestephen`.
