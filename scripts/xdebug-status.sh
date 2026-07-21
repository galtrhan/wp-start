#!/usr/bin/env bash
# Print Xdebug status inside the php container (repo root).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
# shellcheck source=docker-env.sh
source "$ROOT/scripts/docker-env.sh"

if ! docker compose ps --status running php 2>/dev/null | grep -q php; then
    echo "php container is not running. Start with: ./site start" >&2
    exit 1
fi

docker compose exec -T php php -r '
$mode = ini_get("xdebug.mode");
echo "xdebug extension: " . (extension_loaded("xdebug") ? "yes" : "NO") . PHP_EOL;
echo "xdebug.mode: " . ($mode !== false && $mode !== "" ? $mode : "(empty — debugging disabled)") . PHP_EOL;
echo "xdebug.start_with_request: " . ini_get("xdebug.start_with_request") . PHP_EOL;
echo "xdebug.client_host: " . ini_get("xdebug.client_host") . PHP_EOL;
if (is_readable("/tmp/xdebug.log")) {
    echo "--- last lines of /tmp/xdebug.log ---" . PHP_EOL;
    echo implode("", array_slice(file("/tmp/xdebug.log"), -5));
}
'
