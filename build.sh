#!/bin/sh
# Local build using the pins in versions.env.
set -eu
cd "$(dirname "$0")"
set -a
# shellcheck disable=SC1091
. ./versions.env
set +a

if command -v docker >/dev/null 2>&1; then
  engine=docker
elif command -v podman >/dev/null 2>&1; then
  engine=podman
else
  echo "docker or podman is required" >&2
  exit 1
fi

exec "$engine" build \
  --build-arg "TIMESCALE_TAG=${TIMESCALE_TAG}" \
  --build-arg "PGVECTOR_TAG=${PGVECTOR_TAG}" \
  --build-arg "PGVECTORSCALE_TAG=${PGVECTORSCALE_TAG}" \
  --build-arg "SYSTEM_STATS_TAG=${SYSTEM_STATS_TAG}" \
  --build-arg "POSTGRESML_TAG=${POSTGRESML_TAG}" \
  -t pgvectorscaledb:pg18 \
  "$@" \
  .
