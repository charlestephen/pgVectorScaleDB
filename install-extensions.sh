#!/usr/bin/env bash
# Build pgvector, pgvectorscale, system_stats, and postgresml (when it
# supports this PostgreSQL major) into the TimescaleDB image.
set -euo pipefail

: "${PGVECTOR_TAG:?}"
: "${PGVECTORSCALE_TAG:?}"
: "${SYSTEM_STATS_TAG:?}"
: "${POSTGRESML_TAG:?}"

pg_major="$(pg_config --version | awk '{print $2}' | cut -d. -f1)"
echo "Building against $(pg_config --version) from ${TIMESCALE_TAG:-the base image}"
test "$(pg_config --pkglibdir)" = /usr/local/lib/postgresql
test "$(pg_config --sharedir)" = /usr/local/share/postgresql

apk add --no-cache \
  bash \
  build-base \
  ca-certificates \
  clang \
  clang-dev \
  curl \
  git \
  jq \
  linux-headers \
  llvm-dev \
  musl-dev \
  openssl-dev \
  pkgconf

libclang="$(find /usr/lib \( -name 'libclang.so' -o -name 'libclang.so.*' \) -print -quit)"
echo "libclang=${libclang:-missing}"
test -n "$libclang"
export LIBCLANG_PATH="$(dirname "$libclang")"

if ! command -v rustc >/dev/null 2>&1; then
  curl --proto '=https' --tlsv1.2 -fsSL https://sh.rustup.rs \
    | sh -s -- -y --profile minimal --default-toolchain stable
fi
# shellcheck disable=SC1091
. "${CARGO_HOME:-$HOME/.cargo}/env"
export PATH="${CARGO_HOME:-$HOME/.cargo}/bin:${PATH}"
# Alpine's Rust musl target links statically and then cannot find libssl.a.
# The TimescaleDB image provides shared libraries, which a Postgres extension needs.
export RUSTFLAGS="${RUSTFLAGS:-} -C target-feature=-crt-static"

jobs="$(getconf _NPROCESSORS_ONLN)"
mkdir -p /src

echo "pgvector ${PGVECTOR_TAG}"
git clone --depth 1 --branch "$PGVECTOR_TAG" https://github.com/pgvector/pgvector.git /src/pgvector
make -C /src/pgvector -j"$jobs" OPTFLAGS=""
make -C /src/pgvector install

echo "system_stats ${SYSTEM_STATS_TAG}"
git clone --depth 1 --branch "$SYSTEM_STATS_TAG" https://github.com/EnterpriseDB/system_stats.git /src/system_stats
make -C /src/system_stats -j"$jobs" USE_PGXS=1
make -C /src/system_stats install USE_PGXS=1

echo "pgvectorscale ${PGVECTORSCALE_TAG}"
git clone --depth 1 --branch "$PGVECTORSCALE_TAG" https://github.com/timescale/pgvectorscale.git /src/pgvectorscale
cd /src/pgvectorscale/pgvectorscale
pgrx_version="$(cargo metadata --format-version 1 | jq -r '[.packages[] | select(.name == "pgrx") | .version] | unique | .[0]')"
cargo install --locked cargo-pgrx --version "$pgrx_version"
cargo pgrx init --pg"${pg_major}" "$(command -v pg_config)"
cargo pgrx install --release

if [ "$POSTGRESML_TAG" != "skip" ]; then
  echo "postgresml ${POSTGRESML_TAG}"
  git clone --depth 1 --branch "$POSTGRESML_TAG" https://github.com/postgresml/postgresml.git /src/postgresml
  if grep -Eq '^pg'"${pg_major}"' =' /src/postgresml/pgml-extension/Cargo.toml; then
    apk add --no-cache python3-dev py3-pip openblas-dev
    cd /src/postgresml/pgml-extension
    cargo pgrx install --release --no-default-features --features "pg${pg_major},python"
  else
    echo "postgresml ${POSTGRESML_TAG} has no pg${pg_major} feature; not installing"
  fi
else
  echo "postgresml skipped (no PostgreSQL ${pg_major} release yet)"
fi

sharedir="$(pg_config --sharedir)/extension"
for control in vector.control vectorscale.control system_stats.control; do
  test -f "${sharedir}/${control}"
done
if [ -f "${sharedir}/pgml.control" ]; then
  echo "installed pgml"
fi
echo "extension build finished"
