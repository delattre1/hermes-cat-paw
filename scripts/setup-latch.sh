#!/usr/bin/env bash
# Prepare Cat Paw Latch from source on this machine. Does not launch the GUI:
# keep `just app` in a visible terminal so approval prompts stay on screen.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LATCH_DIR="${LATCH_DIR:-$ROOT/../cat-paw-latch}"
LATCH_REPO="${LATCH_REPO:-https://github.com/kumanaya/cat-paw-latch.git}"

need() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "Missing '$1'. On Arch/Omarchy: sudo pacman -S --needed base-devel just git python bubblewrap fuse2" >&2
    echo "Also need Node.js 22+ (node -v) and npm." >&2
    exit 1
  }
}

need git
need just
need node
need npm
need python3

node_major="$(node -p "process.versions.node.split('.')[0]")"
if (( node_major < 22 )); then
  echo "Node.js 22 or newer is required (found $(node -v))." >&2
  exit 1
fi

if [[ "$(uname -s)" == "Linux" ]] && ! command -v bwrap >/dev/null 2>&1; then
  echo "bubblewrap (bwrap) is required on Linux. Arch/Omarchy: sudo pacman -S --needed bubblewrap" >&2
  exit 1
fi

if [[ ! -d "$LATCH_DIR/.git" ]]; then
  mkdir -p "$(dirname "$LATCH_DIR")"
  git clone "$LATCH_REPO" "$LATCH_DIR"
fi

(
  cd "$LATCH_DIR"
  just install
)

cat <<EOF
Cat Paw Latch is ready at $LATCH_DIR

Start it in a visible terminal and leave it running:

  cd $LATCH_DIR
  just app

Sign in, keep the approval window visible, then continue Hermes setup with
scripts/install.sh (Linux/Omarchy) or scripts/install.ps1 (Windows).
EOF
