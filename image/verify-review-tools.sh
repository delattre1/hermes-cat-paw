#!/bin/sh
# Confirm the CLIs baked by image/install-review-tools.sh are on PATH.
# Run at docker build and from scripts/verify.sh. Safe as hermes or root.
set -eu

PATH="/opt/cat-paw/bin:/usr/local/bin:$PATH"
export PATH

# Command names (not apt package names). Keep in sync with the pin.
TOOLS="
jq
yq
gh
gitleaks
semgrep
trivy
osv-scanner
kubesec
hadolint
shellcheck
nmap
masscan
sqlmap
hashcat
dig
whois
nc
tcpdump
dirb
subfinder
nuclei
pd-httpx
katana
naabu
dnsx
ffuf
gobuster
amass
trufflehog
cosign
syft
grype
dalfox
feroxbuster
slsa-verifier
bandit
checkov
snyk
"

missing=0
for t in $TOOLS; do
  if ! command -v "$t" >/dev/null 2>&1; then
    echo "review-tools: missing $t" >&2
    missing=1
  else
    echo "review-tools: $t=$(command -v "$t")"
  fi
done

if [ -x /opt/cat-paw/bin/httpx ]; then
  echo "review-tools: httpx=/opt/cat-paw/bin/httpx"
else
  echo "review-tools: missing ProjectDiscovery httpx at /opt/cat-paw/bin/httpx" >&2
  missing=1
fi

if [ -d /opt/cat-paw/nuclei-templates ]; then
  echo "review-tools: nuclei-templates=/opt/cat-paw/nuclei-templates"
else
  echo "review-tools: missing nuclei templates" >&2
  missing=1
fi

if [ -f /usr/share/wordlists/common.txt ]; then
  echo "review-tools: wordlists=/usr/share/wordlists"
else
  echo "review-tools: missing wordlists" >&2
  missing=1
fi

if command -v secretsdump.py >/dev/null 2>&1; then
  echo "review-tools: impacket=$(command -v secretsdump.py)"
elif command -v impacket-secretsdump >/dev/null 2>&1; then
  echo "review-tools: impacket=$(command -v impacket-secretsdump)"
else
  echo "review-tools: missing impacket (secretsdump.py)" >&2
  missing=1
fi

if [ "$missing" -ne 0 ]; then
  echo "review-tools: image is incomplete. Rebuild with scripts/install.sh." >&2
  exit 1
fi

smoke() {
  bin="$1"
  if timeout 25 "$bin" --version >/dev/null 2>&1; then
    return 0
  fi
  if timeout 25 "$bin" -version >/dev/null 2>&1; then
    return 0
  fi
  if timeout 25 "$bin" version >/dev/null 2>&1; then
    return 0
  fi
  echo "review-tools: $bin did not start" >&2
  return 1
}

# Skip nc/tcpdump/dirb (no useful version flag / they wait on stdin).
failed=0
for t in $TOOLS; do
  case "$t" in
    nc | tcpdump | dirb | masscan | ffuf) continue ;;
  esac
  smoke "$t" || failed=1
done
if [ "$failed" -ne 0 ]; then
  exit 1
fi

echo "review-tools: all baked CLIs start"
