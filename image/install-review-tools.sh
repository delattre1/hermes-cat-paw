#!/usr/bin/env bash
# Bake pinned review + recon CLIs into the image. Run as root at docker build.
set -euo pipefail

PIN="${REVIEW_TOOLS_PIN:-/opt/cat-paw/review-tools.pin}"
DEST="${REVIEW_TOOLS_DEST:-/usr/local/bin}"
UV_HOME="${REVIEW_TOOLS_UV_DIR:-/opt/cat-paw/uv-tools}"
CATPAW_BIN="${REVIEW_TOOLS_CATPAW_BIN:-/opt/cat-paw/bin}"
NUCLEI_TEMPLATES="${NUCLEI_TEMPLATES:-/opt/cat-paw/nuclei-templates}"
TRIVY_CACHE_DIR="${TRIVY_CACHE_DIR:-/opt/cat-paw/trivy-cache}"
GRYPE_DB_CACHE_DIR="${GRYPE_DB_CACHE_DIR:-/opt/cat-paw/grype-db}"

if [[ ! -f "$PIN" ]]; then
  echo "install-review-tools: missing pin $PIN" >&2
  exit 1
fi

case "$(uname -m)" in
  x86_64 | amd64) SLOT=amd64 ;;
  aarch64 | arm64) SLOT=arm64 ;;
  *)
    echo "install-review-tools: unsupported arch $(uname -m)" >&2
    exit 1
    ;;
esac

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

reset_stanza() {
  TOOL=""
  VERSION=""
  KIND=""
  AMD64_URL=""
  AMD64_SHA256=""
  ARM64_URL=""
  ARM64_SHA256=""
  FILE_PATH=""
}

url_for_slot() {
  if [[ "$SLOT" == amd64 ]]; then
    printf '%s\n' "$AMD64_URL"
  else
    printf '%s\n' "$ARM64_URL"
  fi
}

sha_for_slot() {
  if [[ "$SLOT" == amd64 ]]; then
    printf '%s\n' "$AMD64_SHA256"
  else
    printf '%s\n' "$ARM64_SHA256"
  fi
}

download_verified() {
  local url="$1" sha="$2" out="$3"
  [[ -n "$url" && -n "$sha" ]] || {
    echo "install-review-tools: $TOOL missing $SLOT url/sha256" >&2
    exit 1
  }
  echo "install-review-tools: fetching $TOOL ($SLOT)"
  curl -fsSL --retry 3 --retry-delay 2 --max-time 300 -o "$out" "$url"
  echo "${sha}  ${out}" | sha256sum -c -
}

pick_payload() {
  local dir="$1" name="$2" f
  if [[ -f "$dir/$name" ]]; then
    printf '%s\n' "$dir/$name"
    return 0
  fi
  f="$(find "$dir" -type f -name "$name" -print -quit)"
  if [[ -n "$f" ]]; then
    printf '%s\n' "$f"
    return 0
  fi
  f="$(find "$dir" -type f \( -name "${name}_*" -o -name "${name}-*" \) \
    ! -name '*.md' ! -name '*.txt' ! -name '*.1' ! -name '*.sh' -print -quit)"
  if [[ -n "$f" ]]; then
    printf '%s\n' "$f"
    return 0
  fi
  echo "install-review-tools: no payload named $name in archive" >&2
  find "$dir" -type f >&2
  return 1
}

install_archive() {
  local archive="$1" extract="$TMP/extract-$TOOL" payload
  rm -rf "$extract"
  mkdir -p "$extract"
  case "$archive" in
    *.zip) unzip -q -o "$archive" -d "$extract" ;;
    *) tar -xzf "$archive" -C "$extract" ;;
  esac
  payload="$(pick_payload "$extract" "$TOOL")"
  install -m 0755 "$payload" "$DEST/$TOOL"
}

install_tar() {
  local archive="$TMP/$TOOL.tar.gz"
  download_verified "$(url_for_slot)" "$(sha_for_slot)" "$archive"
  install_archive "$archive"
}

install_zip() {
  local archive="$TMP/$TOOL.zip"
  download_verified "$(url_for_slot)" "$(sha_for_slot)" "$archive"
  install_archive "$archive"
}

install_bin() {
  local raw="$TMP/$TOOL.bin"
  download_verified "$(url_for_slot)" "$(sha_for_slot)" "$raw"
  install -m 0755 "$raw" "$DEST/$TOOL"
}

install_file() {
  local dest="${FILE_PATH:-}"
  [[ -n "$dest" ]] || {
    echo "install-review-tools: $TOOL kind=file needs path=" >&2
    exit 1
  }
  mkdir -p "$(dirname "$dest")"
  download_verified "$(url_for_slot)" "$(sha_for_slot)" "$TMP/$TOOL.file"
  install -m 0644 "$TMP/$TOOL.file" "$dest"
}

install_uv() {
  local spec="$TOOL"
  [[ -n "$VERSION" ]] && spec="${TOOL}==${VERSION}"
  command -v uv >/dev/null || {
    echo "install-review-tools: uv missing; cannot install $TOOL" >&2
    exit 1
  }
  echo "install-review-tools: uv tool install $spec"
  UV_TOOL_BIN_DIR="$DEST" UV_TOOL_DIR="$UV_HOME" \
    uv tool install --force "$spec"
  chmod -R a+rX "$UV_HOME"
}

install_npm() {
  local spec="$TOOL"
  [[ -n "$VERSION" ]] && spec="${TOOL}@${VERSION}"
  command -v npm >/dev/null || {
    echo "install-review-tools: npm missing; cannot install $TOOL" >&2
    exit 1
  }
  echo "install-review-tools: npm install -g $spec"
  npm install -g --allow-scripts="$TOOL" "$spec"
}

place_pd_httpx() {
  if [[ -x "$DEST/httpx" ]]; then
    mkdir -p "$CATPAW_BIN"
    mv "$DEST/httpx" "$CATPAW_BIN/httpx"
    ln -sfn "$CATPAW_BIN/httpx" "$DEST/pd-httpx"
    echo "install-review-tools: ProjectDiscovery httpx -> $CATPAW_BIN/httpx (also pd-httpx)"
  fi
}

prefetch_dbs() {
  mkdir -p "$NUCLEI_TEMPLATES" "$TRIVY_CACHE_DIR" "$GRYPE_DB_CACHE_DIR"
  export TRIVY_CACHE_DIR GRYPE_DB_CACHE_DIR
  if command -v nuclei >/dev/null; then
    echo "install-review-tools: nuclei templates -> $NUCLEI_TEMPLATES"
    nuclei -update-templates -ud "$NUCLEI_TEMPLATES" -duc
  fi
  if command -v trivy >/dev/null; then
    echo "install-review-tools: trivy vuln DB -> $TRIVY_CACHE_DIR"
    trivy image --download-db-only --cache-dir "$TRIVY_CACHE_DIR"
  fi
  if command -v grype >/dev/null; then
    echo "install-review-tools: grype DB -> $GRYPE_DB_CACHE_DIR"
    GRYPE_DB_CACHE_DIR="$GRYPE_DB_CACHE_DIR" grype db update
  fi
  chmod -R a+rX /opt/cat-paw /usr/share/wordlists
}

APT_PACKAGES=()
STANZAS=()

flush_collect() {
  [[ -z "$TOOL" ]] && return 0
  if [[ "$KIND" == apt ]]; then
    APT_PACKAGES+=("$TOOL")
  else
    STANZAS+=("${TOOL}|${VERSION}|${KIND}|${AMD64_URL}|${AMD64_SHA256}|${ARM64_URL}|${ARM64_SHA256}|${FILE_PATH}")
  fi
}

reset_stanza
while IFS= read -r line || [[ -n "$line" ]]; do
  case "$line" in
    '' | \#*) continue ;;
  esac
  key="${line%%=*}"
  val="${line#*=}"
  if [[ "$key" == tool && -n "$TOOL" ]]; then
    flush_collect
    reset_stanza
  fi
  case "$key" in
    tool) TOOL="$val" ;;
    version) VERSION="$val" ;;
    kind) KIND="$val" ;;
    path) FILE_PATH="$val" ;;
    amd64_url) AMD64_URL="$val" ;;
    amd64_sha256) AMD64_SHA256="$val" ;;
    arm64_url) ARM64_URL="$val" ;;
    arm64_sha256) ARM64_SHA256="$val" ;;
    *)
      echo "install-review-tools: unknown pin key: $key" >&2
      exit 1
      ;;
  esac
done <"$PIN"
flush_collect

mkdir -p "$DEST" "$UV_HOME" "$CATPAW_BIN"
export PATH="$CATPAW_BIN:$DEST:$PATH"

if ((${#APT_PACKAGES[@]})); then
  echo "install-review-tools: apt ${APT_PACKAGES[*]}"
  export DEBIAN_FRONTEND=noninteractive
  apt-get update
  apt-get install -y --no-install-recommends "${APT_PACKAGES[@]}"
  rm -rf /var/lib/apt/lists/*
fi

for CURRENT in "${STANZAS[@]}"; do
  IFS='|' read -r TOOL VERSION KIND AMD64_URL AMD64_SHA256 ARM64_URL ARM64_SHA256 FILE_PATH <<<"$CURRENT"
  case "$KIND" in
    tar) install_tar ;;
    zip) install_zip ;;
    bin) install_bin ;;
    file) install_file ;;
    uv) install_uv ;;
    npm) install_npm ;;
    *)
      echo "install-review-tools: unknown kind $KIND for $TOOL" >&2
      exit 1
      ;;
  esac
done

place_pd_httpx
prefetch_dbs

rm -rf /root/.cache/uv /root/.cache/pip /tmp/uv-cache /root/.npm
echo "install-review-tools: done ($SLOT)"
