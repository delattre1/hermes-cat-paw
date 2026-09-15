#!/usr/bin/env bash
# Provision Hermes Cat Paw: reuse an existing Plow login and free line when
# present. With no --line, mint the first free dashboard name automatically.
# Do not create a new assistant line unless --new-line is passed.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TOOLS="$ROOT/.tools/plow-agents"
CREDENTIALS="$ROOT/plow-credentials"
TOKEN_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/plow/token"
# Agent Index identity for this product. Never inherit a host AGENT_ID.
AGENT_ID="hermes-cat-paw"
export AGENT_ID

LINE=""
NEW_LINE=0

usage() {
  cat <<EOF
Usage: $(basename "$0") [--line NAME] [--new-line]

  --line NAME   Mint this free line by dashboard name (Willow) or uid (ln_p1)
  --new-line    Provision a new assistant line. Requires a phone SMS.
                Do not pass this when a free line already exists.

With no flags, the installer is non-interactive after phone login:
  - skip login when ~/.config/plow/token exists
  - skip mint when plow-credentials exists
  - otherwise mint the first free line (no assistant assigned), by name
  - start Docker Compose with AGENT_ID=hermes-cat-paw

Occupied lines are never minted. Pass --line only to override the automatic
choice. Do not call plow-agents mint or docker compose by hand.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --line)
      LINE="${2:-}"
      [[ -n "$LINE" ]] || { echo "install.sh: --line needs a name or uid." >&2; exit 1; }
      shift 2
      ;;
    --line=*)
      LINE="${1#*=}"
      shift
      ;;
    --new-line)
      NEW_LINE=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    -*)
      echo "install.sh: unknown option: $1" >&2
      usage >&2
      exit 1
      ;;
    *)
      if [[ -n "$LINE" ]]; then
        echo "install.sh: unexpected argument: $1" >&2
        exit 1
      fi
      LINE="$1"
      shift
      ;;
  esac
done

ensure_cli() {
  if [[ ! -d "$TOOLS/.git" ]]; then
    mkdir -p "$(dirname "$TOOLS")"
    git clone https://github.com/plow-pbc/plow-agents.git "$TOOLS"
  fi
}

plow() {
  python3 "$TOOLS/bin/plow-agents" "$@"
}

has_account_token() {
  [[ -s "$TOKEN_FILE" ]]
}

# Prints TSV rows: uid, name, number, status (status is "free" or an agent uid).
lines_tsv() {
  plow lines | awk -F '\t' 'NR > 1 && NF >= 4 { print }'
}

lower() {
  printf '%s' "$1" | tr '[:upper:]' '[:lower:]'
}

print_free_names() {
  local uid name number status count=0
  while IFS=$'\t' read -r uid name number status; do
    [[ "$status" == "free" ]] || continue
    printf '  %s\n' "$name"
    count=$((count + 1))
  done < <(lines_tsv)
  if (( count == 0 )); then
    echo "  (none)"
  fi
}

occupied_names() {
  local uid name number status names=()
  while IFS=$'\t' read -r uid name number status; do
    [[ "$status" == "free" ]] && continue
    names+=("$name")
  done < <(lines_tsv)
  if ((${#names[@]})); then
    local IFS=', '
    printf '%s' "${names[*]}"
  fi
}

# First free dashboard name, sorted so a non-interactive run is deterministic.
first_free_name() {
  lines_tsv | awk -F '\t' '$4 == "free" && $2 != "" { print $2 }' | LC_ALL=C sort | head -n 1
}

# Resolve a dashboard name, uid, or 1-based free-list index to uid + name + status.
resolve_line() {
  local query="$1"
  local q uid name number status i=0
  q="$(lower "$query")"
  while IFS=$'\t' read -r uid name number status; do
    if [[ "$q" == "$(lower "$uid")" || "$q" == "$(lower "$name")" ]]; then
      printf '%s\t%s\t%s\n' "$uid" "$name" "$status"
      return 0
    fi
  done < <(lines_tsv)
  if [[ "$query" =~ ^[0-9]+$ ]]; then
    while IFS=$'\t' read -r uid name number status; do
      [[ "$status" == "free" ]] || continue
      i=$((i + 1))
      if [[ "$i" == "$query" ]]; then
        printf '%s\t%s\t%s\n' "$uid" "$name" "$status"
        return 0
      fi
    done < <(lines_tsv)
  fi
  return 1
}

mint_free_line() {
  local query="$1" resolved uid name status
  resolved="$(resolve_line "$query")" || {
    echo "install.sh: unknown line '$query'." >&2
    echo "Free lines:" >&2
    print_free_names >&2
    exit 1
  }
  IFS=$'\t' read -r uid name status <<<"$resolved"
  if [[ "$status" != "free" ]]; then
    echo "install.sh: $name already has an assistant assigned." >&2
    echo "Delete that agent in Plow, pick a free line, or pass --new-line." >&2
    echo "Free lines:" >&2
    print_free_names >&2
    exit 1
  fi
  echo "Minting free line $name."
  plow mint "$uid"
}

login_account() {
  if (( NEW_LINE )); then
    echo "Provisioning a new assistant line (phone SMS)."
    plow login --new-line
  else
    plow login
  fi
}

# Docker creates a directory when this bind-mount path is missing. Mint then
# cannot write the file, and the container sees no credential.
if [[ -d "$CREDENTIALS" ]]; then
  if [[ -n "$(find "$CREDENTIALS" -mindepth 1 -maxdepth 1 -print -quit)" ]]; then
    echo "install.sh: plow-credentials is a non-empty directory." >&2
    echo "That usually means docker compose ran before mint. Move it aside and re-run." >&2
    exit 1
  fi
  echo "install.sh: removing empty plow-credentials directory left by docker compose."
  rmdir "$CREDENTIALS"
fi

if [[ -f "$CREDENTIALS" ]]; then
  echo "Using existing plow-credentials. Skipping Plow login."
else
  ensure_cli

  if (( NEW_LINE )); then
    login_account
  elif has_account_token; then
    echo "Using existing Plow account token. Skipping phone login."
  else
    echo "No account token yet. Logging in without creating a new line."
    echo "Keep this script in the foreground. When it prints a destination"
    echo "number and Plow Activate: <code>, show those two lines to the owner"
    echo "and wait for them to reply: feito"
    login_account
  fi

  free_count="$(lines_tsv | awk -F '\t' '$4 == "free" { n++ } END { print n+0 }')"
  if (( free_count == 0 )) && (( ! NEW_LINE )); then
    occupied="$(occupied_names)"
    echo "install.sh: no free Plow line on this account." >&2
    if [[ -n "$occupied" ]]; then
      echo "Already assigned: $occupied" >&2
    fi
    echo "Pass --new-line to create one, or delete an assistant in Plow." >&2
    exit 1
  fi

  if [[ -z "$LINE" ]]; then
    LINE="$(first_free_name)"
    if [[ -z "$LINE" ]]; then
      echo "install.sh: no free Plow line to mint after login." >&2
      echo "Pass --new-line to create one, or delete an assistant in Plow." >&2
      exit 1
    fi
    echo "Free Plow lines (no assistant assigned):"
    print_free_names
    echo "Using free line $LINE. Pass --line NAME to override; --new-line to create another."
  fi

  mint_free_line "$LINE"
fi

if [[ ! -f "$CREDENTIALS" ]]; then
  echo "install.sh: plow-credentials is still missing after mint." >&2
  echo "Do not run docker compose up until this file exists. Re-run this script." >&2
  exit 1
fi

echo "Starting Compose with AGENT_ID=$AGENT_ID"
docker compose -f "$ROOT/compose.yml" up --build -d
# Repair sticky-home ledger ownership, wait for state.db, and report as uid hermes.
# Do not docker compose exec the Index client as root.
"$ROOT/scripts/verify.sh"
