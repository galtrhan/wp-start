#!/usr/bin/env bash
# Run a command inside the Docker PHP service with cwd set to a theme or plugin.
# Requires Docker and ./site start.
#
# Usage (from repository root):
#   ./scripts/dev-php.sh -w wp-content/plugins/my-plugin ./vendor/bin/phpcs my-file.php
#   ./scripts/dev-php.sh ./vendor/bin/phpcs file.php   # first matching THEME_NAME / PLUGIN_NAME / auto-detect
#
# Set THEME_NAME and/or PLUGIN_NAME in .env to pin targets.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
# shellcheck source=docker-env.sh
source "$ROOT/scripts/docker-env.sh"
# shellcheck source=dev-resolve.sh
source "$ROOT/scripts/dev-resolve.sh"

WORKDIR=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        -w|--workdir)
            WORKDIR="${2:?missing path after $1}"
            shift 2
            ;;
        *)
            break
            ;;
    esac
done

if [[ -z "$WORKDIR" ]]; then
    if ! collect_dev_targets "$ROOT"; then
        echo "Error: no custom theme or plugin found under wp-content/." >&2
        echo "Set THEME_NAME / PLUGIN_NAME in .env or add composer.json / package.json / phpcs.xml." >&2
        exit 1
    fi
    WORKDIR="${DEV_TARGETS[0]}"
fi

if [[ ! -d "$ROOT/$WORKDIR" ]]; then
    echo "Error: workdir not found: $WORKDIR" >&2
    exit 1
fi

exec docker compose exec -T -w "/var/www/html/$WORKDIR" php "$@"
