# Changelog

All notable changes to this project are documented here. Format loosely
follows [Keep a Changelog](https://keepachangelog.com/). Images are rebuilt
daily to track the latest extension releases; those rebuilds are recorded in
`versions.env`, not here.

## Unreleased

### Added

- `compose.yml` for running the published image.
- Docker Hub overview (`docs/dockerhub.md`), synced to
  `docker.io/charlestephen/pgvectorscaledb` by the publish workflow.
- `renovate.json` and sponsorship metadata.
- GPL-3.0 `LICENSE` for the build files and scripts.
- Slack notification workflow for publish results.

### Changed

- Renamed `Dockerfile` to `Containerfile`; the publish workflow and
  `build.sh` build from it.
- GitHub Actions are pinned to commit SHAs.
