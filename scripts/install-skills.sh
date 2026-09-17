#!/usr/bin/env bash
# Load the pinned recon skill pack into a Hermes home. Default destination is
# the running Compose agent's /var/lib/hermes. Authorized testing only: the
# pack itself says so, and so does skills/recon-pack/SKILL.md.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PIN="$ROOT/vendor/recon-skills.pin"
TOOLS="$ROOT/.tools/recon-skills"
COMPOSE=(docker compose -f "$ROOT/compose.yml")
SERVICE=hermes-cat-paw
HOME_DIR=""
LIST_ONLY=0

# Segment directories from uphiago/recon-skills. Do not copy banner.png or .git.
SEGMENTS=(auth chains infra meta recon redteam)
DOCS=(LICENSE SOUL.md AGENTS.md STYLE.md README.md)

usage() {
  cat <<EOF
Usage: $(basename "$0") [--home HERMES_HOME] [--list]

  --home DIR  Install into DIR/skills/recon-skills (existing Hermes).
              Default: the running Compose container.
  --list      Fetch the pin and print skill counts. Do not copy.

These playbooks are for targets the owner owns or has written permission
to test. Latch should approve live probes (browser, nmap, curl).
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --home)
      HOME_DIR="${2:-}"
      [[ -n "$HOME_DIR" ]] || { echo "install-skills.sh: --home needs a directory." >&2; exit 1; }
      shift 2
      ;;
    --home=*)
      HOME_DIR="${1#*=}"
      shift
      ;;
    --list)
      LIST_ONLY=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    -*)
      echo "install-skills.sh: unknown option: $1" >&2
      usage >&2
      exit 1
      ;;
    *)
      echo "install-skills.sh: unexpected argument: $1" >&2
      exit 1
      ;;
  esac
done

repo="$(sed -n 's/^repo=//p' "$PIN")"
sha="$(sed -n 's/^sha=//p' "$PIN")"
[[ -n "$repo" && -n "$sha" ]] || { echo "install-skills.sh: malformed $PIN" >&2; exit 1; }

ensure_clone() {
  mkdir -p "$(dirname "$TOOLS")"
  if [[ ! -d "$TOOLS/.git" ]]; then
    echo "install-skills.sh: cloning recon-skills"
    git clone "$repo" "$TOOLS"
  fi
  echo "install-skills.sh: checking out $sha"
  git -C "$TOOLS" fetch origin "$sha"
  git -C "$TOOLS" checkout --detach "$sha"
  got="$(git -C "$TOOLS" rev-parse HEAD)"
  if [[ "$got" != "$sha" ]]; then
    echo "install-skills.sh: expected $sha, got $got" >&2
    exit 1
  fi
}

count_skills() {
  find "$TOOLS" -name SKILL.md -type f | wc -l
}

ensure_clone

n="$(count_skills)"
echo "install-skills.sh: $n SKILL.md files at $sha"

if (( LIST_ONLY )); then
  find "$TOOLS" -name SKILL.md -type f | sed "s|^$TOOLS/||" | sort
  exit 0
fi

archive() {
  tar -C "$TOOLS" -cf - "${SEGMENTS[@]}" "${DOCS[@]}"
}

install_tree() {
  local dest="$1"
  mkdir -p "$dest"
  archive | tar -C "$dest" -xf -
  echo "install-skills.sh: wrote $dest ($n skills)"
}

if [[ -n "$HOME_DIR" ]]; then
  install_tree "$HOME_DIR/skills/recon-skills"
  exit 0
fi

if [[ -z "$("${COMPOSE[@]}" ps -q "$SERVICE" 2>/dev/null)" ]]; then
  echo "install-skills.sh: Compose agent is not running." >&2
  echo "Start it with scripts/install.sh, or pass --home HERMES_HOME." >&2
  exit 1
fi

echo "install-skills.sh: copying pack into the Compose agent"
"${COMPOSE[@]}" exec -T -u 0 "$SERVICE" mkdir -p /var/lib/hermes/skills/recon-skills
archive | "${COMPOSE[@]}" exec -T -u 0 "$SERVICE" tar -C /var/lib/hermes/skills/recon-skills -xf -
"${COMPOSE[@]}" exec -T -u 0 "$SERVICE" chown -R hermes:hermes /var/lib/hermes/skills/recon-skills
landed="$("${COMPOSE[@]}" exec -T -u hermes "$SERVICE" sh -c 'find /var/lib/hermes/skills/recon-skills -name SKILL.md -type f | wc -l')"
landed="${landed//$'\r'/}"
echo "install-skills.sh: container pack has $landed SKILL.md files"
echo "install-skills.sh: authorized testing only. Live probes go through Latch."
