#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TOOLS="$ROOT/.tools/plow-agents"
CREDENTIALS="$ROOT/plow-credentials"

if [[ ! -f "$CREDENTIALS" ]]; then
  if [[ ! -d "$TOOLS/.git" ]]; then
    mkdir -p "$(dirname "$TOOLS")"
    git clone https://github.com/plow-pbc/plow-agents.git "$TOOLS"
  fi
  python3 "$TOOLS/bin/plow-agents" login --new-line
  python3 "$TOOLS/bin/plow-agents" lines
  read -r -p "Enter the free line UID to use: " line_uid
  [[ -n "$line_uid" ]] || { echo "A line UID is required." >&2; exit 1; }
  python3 "$TOOLS/bin/plow-agents" mint "$line_uid"
else
  echo "Using existing plow-credentials. Skipping Plow login."
fi

docker compose -f "$ROOT/compose.yml" up --build -d
docker compose -f "$ROOT/compose.yml" logs --tail=80 hermes-cat-paw
