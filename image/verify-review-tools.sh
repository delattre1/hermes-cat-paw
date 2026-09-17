#!/bin/sh
# Confirm the CLIs baked by image/install-review-tools.sh are on PATH.
# Run at docker build and from scripts/verify.sh. Safe as hermes or root.
set -eu

missing=0
# Keep in sync with vendor/review-tools.pin (apt + release + uv names).
for t in jq yq gh gitleaks semgrep trivy osv-scanner kubesec hadolint shellcheck; do
  if ! command -v "$t" >/dev/null 2>&1; then
    echo "review-tools: missing $t" >&2
    missing=1
  else
    echo "review-tools: $t=$(command -v "$t")"
  fi
done

if [ "$missing" -ne 0 ]; then
  echo "review-tools: image is incomplete. Rebuild with scripts/install.sh." >&2
  exit 1
fi

# Smoke that the binaries actually start (no network, no scan).
# Flags differ; try --version, then version, then -v.
smoke() {
  bin="$1"
  if timeout 20 "$bin" --version >/dev/null 2>&1; then
    return 0
  fi
  if timeout 20 "$bin" version >/dev/null 2>&1; then
    return 0
  fi
  if timeout 20 "$bin" -v >/dev/null 2>&1; then
    return 0
  fi
  echo "review-tools: $bin did not start" >&2
  return 1
}

failed=0
for t in jq yq gh gitleaks semgrep trivy osv-scanner kubesec hadolint shellcheck; do
  smoke "$t" || failed=1
done
if [ "$failed" -ne 0 ]; then
  exit 1
fi

echo "review-tools: all baked CLIs start"
