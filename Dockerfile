# syntax=docker/dockerfile:1

ARG TIMESCALE_TAG=latest-pg18
FROM timescale/timescaledb:${TIMESCALE_TAG} AS build

USER root
ARG TIMESCALE_TAG
ARG TARGETARCH
ARG PGVECTOR_TAG=v0.8.7
ARG PGVECTORSCALE_TAG=0.9.1
ARG SYSTEM_STATS_TAG=v4.1
ARG POSTGRESML_TAG=skip

COPY install-extensions.sh /tmp/install-extensions.sh
RUN --mount=type=cache,target=/root/.cargo,sharing=locked \
    --mount=type=cache,target=/root/.rustup,sharing=locked \
    chmod 755 /tmp/install-extensions.sh \
  && TIMESCALE_TAG="$TIMESCALE_TAG" \
     TARGETARCH="$TARGETARCH" \
     PGVECTOR_TAG="$PGVECTOR_TAG" \
     PGVECTORSCALE_TAG="$PGVECTORSCALE_TAG" \
     SYSTEM_STATS_TAG="$SYSTEM_STATS_TAG" \
     POSTGRESML_TAG="$POSTGRESML_TAG" \
     bash /tmp/install-extensions.sh

ARG TIMESCALE_TAG
FROM timescale/timescaledb:${TIMESCALE_TAG}

ARG TIMESCALE_TAG
ARG PGVECTOR_TAG=v0.8.7
ARG PGVECTORSCALE_TAG=0.9.1
ARG SYSTEM_STATS_TAG=v4.1
ARG POSTGRESML_TAG=skip

COPY --from=build /out/usr/local/lib/postgresql/ /usr/local/lib/postgresql/
COPY --from=build /out/usr/local/share/postgresql/extension/ /usr/local/share/postgresql/extension/
COPY docker-entrypoint-initdb.d/020-extensions.sh /docker-entrypoint-initdb.d/020-extensions.sh

LABEL org.opencontainers.image.source="https://github.com/charlestephen/pgVectorScaleDB" \
      org.opencontainers.image.description="TimescaleDB on PostgreSQL 18 with pgvector, pgvectorscale, and system_stats" \
      org.opencontainers.image.base.name="timescale/timescaledb:${TIMESCALE_TAG}" \
      org.pgvectorscaledb.pgvector="${PGVECTOR_TAG}" \
      org.pgvectorscaledb.pgvectorscale="${PGVECTORSCALE_TAG}" \
      org.pgvectorscaledb.system_stats="${SYSTEM_STATS_TAG}" \
      org.pgvectorscaledb.postgresml="${POSTGRESML_TAG}"
