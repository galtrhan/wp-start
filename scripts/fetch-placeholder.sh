#!/usr/bin/env bash
# Download a single JPG placeholder for offline UPLOADS_FALLBACK=placeholder mode.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT="$ROOT/placeholder.jpg"

if [[ -f "$ROOT/.env" ]]; then
    set -a
    # shellcheck disable=SC1091
    source "$ROOT/.env"
    set +a
fi

# Lorem Picsum serves a random JPG; curl follows redirects.
URL="${PLACEHOLDER_DOWNLOAD_URL:-https://picsum.photos/1200/800.jpg}"

if [[ -f "$OUT" && "${1:-}" != "--force" ]]; then
    echo "Placeholder image already exists: $OUT"
    exit 0
fi

if ! command -v curl >/dev/null 2>&1; then
    echo "Error: curl is required to download the placeholder image." >&2
    exit 1
fi

echo "Downloading placeholder JPG from $URL …"
curl -fsSL -o "$OUT" "$URL"

if [[ ! -s "$OUT" ]]; then
    rm -f "$OUT"
    echo "Error: placeholder download failed or file is empty." >&2
    exit 1
fi

echo "Saved placeholder → $OUT"
