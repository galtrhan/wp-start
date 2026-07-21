#!/usr/bin/env bash
# WP-CLI inside the Docker `php` service (cwd /var/www/html).
# Requires: repository root, Docker Compose, containers running (`./site start`).
#
# Usage (from repository root):
#   ./scripts/wp.sh --allow-root option get siteurl
#   ./scripts/wp.sh --allow-root search-replace old.host new.host --all-tables
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
# shellcheck source=docker-env.sh
source "$ROOT/scripts/docker-env.sh"
exec docker compose exec -T -w /var/www/html php php wp-cli.phar "$@"
