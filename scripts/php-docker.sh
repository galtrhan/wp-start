#!/usr/bin/env bash
# Run PHP inside the Docker `php` service so editors can use it for validation
# (e.g. VS Code / Cursor `php.validate.executablePath`). Forwards all arguments.
#
# Requires: Docker Compose project from this repo root, containers running
# (`./site start` or equivalent). Host paths under this repo become /var/www/html/...
# inside the container (bind mount).
#
# Cursor / VS Code: set
#   "php.validate.executablePath": "/absolute/path/to/wp-start/scripts/php-docker.sh"
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
cd "$ROOT"
# shellcheck source=docker-env.sh
source "$ROOT/scripts/docker-env.sh"

root_host="$ROOT"

map_path() {
    local arg="$1"
    local cand="$arg"

    if [[ "$cand" != /* ]]; then
        printf '%s' "$arg"
        return
    fi

    if command -v realpath >/dev/null 2>&1; then
        if resolved="$(realpath "$cand" 2>/dev/null)" && [[ -n "$resolved" ]]; then
            cand="$resolved"
        fi
    fi

    if [[ "$cand" == "$root_host"/* ]]; then
        printf '%s' "/var/www/html/${cand#"$root_host"/}"
        return
    fi

    printf '%s' "$arg"
}

mapped_args=()
for arg in "$@"; do
    if [[ "$arg" == /* ]]; then
        mapped_args+=( "$(map_path "$arg")" )
    else
        mapped_args+=( "$arg" )
    fi
done

exec docker compose exec -T php php "${mapped_args[@]}"
