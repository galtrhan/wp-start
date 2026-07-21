#!/usr/bin/env bash
# Point this repository at scripts/git-hooks (pre-commit, etc.).
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
git config core.hooksPath scripts/git-hooks
echo "core.hooksPath → scripts/git-hooks"
