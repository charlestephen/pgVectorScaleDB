#!/bin/sh
# Start the image and require the extensions created on first boot.
set -eu

image="${1:?image name}"
if command -v docker >/dev/null 2>&1; then
  engine=docker
elif command -v podman >/dev/null 2>&1; then
  engine=podman
else
  echo "docker or podman is required" >&2
  exit 1
fi

name="pgvs-test-$$"
$engine rm -f "$name" >/dev/null 2>&1 || true
$engine run -d --name "$name" -e POSTGRES_PASSWORD=ci "$image" >/dev/null
trap '$engine rm -f "$name" >/dev/null 2>&1 || true' EXIT

i=0
while [ "$i" -lt 60 ]; do
  count="$($engine exec "$name" psql -U postgres -tA -c \
    "SELECT count(*) FROM pg_extension WHERE extname IN ('timescaledb','vector','vectorscale','system_stats')" \
    2>/dev/null || true)"
  if [ "$count" = "4" ]; then
    $engine exec "$name" psql -U postgres -c \
      "SELECT extname, extversion FROM pg_extension ORDER BY 1"
    exit 0
  fi
  i=$((i + 1))
  sleep 2
done

echo "extensions were not installed" >&2
$engine logs "$name" >&2 || true
exit 1
