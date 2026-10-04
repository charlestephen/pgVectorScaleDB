#!/usr/bin/env bash
# Rewrite versions.env from the latest upstream releases.
set -euo pipefail

dest="${1:-versions.env}"
root="$(cd "$(dirname "$0")" && pwd)"
dest="${root}/${dest#./}"
if [ "$dest" = "$root" ]; then
  dest="${root}/versions.env"
fi

latest_tag() {
  gh api "repos/$1/releases/latest" --jq .tag_name
}

latest_version_tag() {
  gh api "repos/$1/tags" --jq '.[].name' \
    | grep -E '^v[0-9]+\.[0-9]+\.[0-9]+$' \
    | head -n 1
}

pgvector="$(latest_version_tag pgvector/pgvector)"
pgvectorscale="$(latest_tag timescale/pgvectorscale)"
system_stats="$(latest_tag EnterpriseDB/system_stats)"
postgresml="$(latest_tag postgresml/postgresml)"

cargo="$(gh api "repos/postgresml/postgresml/contents/pgml-extension/Cargo.toml?ref=${postgresml}" --jq .content | base64 -d)"
if printf '%s\n' "$cargo" | grep -Eq '^pg18 ='; then
  postgresml_pin="$postgresml"
else
  postgresml_pin="skip"
fi

cat > "$dest" <<EOF
# Refreshed by resolve-versions.sh. CI commits changes and rebuilds.
TIMESCALE_TAG=latest-pg18
PGVECTOR_TAG=${pgvector}
PGVECTORSCALE_TAG=${pgvectorscale}
SYSTEM_STATS_TAG=${system_stats}
POSTGRESML_TAG=${postgresml_pin}
EOF
