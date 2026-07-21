#!/usr/bin/env bash
# Run a command inside the Docker PHP service with cwd set to the custom theme.
# Wrapper around dev-php.sh for backward compatibility.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=dev-resolve.sh
source "$ROOT/scripts/dev-resolve.sh"

if ! resolve_theme_paths "$ROOT"; then
    echo "Error: no custom theme found under wp-content/themes/." >&2
    echo "Set THEME_NAME in .env or use ./scripts/dev-php.sh -w wp-content/plugins/…" >&2
    exit 1
fi

exec "$ROOT/scripts/dev-php.sh" -w "$THEME_REL" "$@"
