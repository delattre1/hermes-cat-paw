---
name: image-tools
description: Use when choosing where a scanner runs, asking what CLIs this agent has, or about to apt-get/go install nmap/subfinder/nuclei/gitleaks inside Hermes. Lists tools baked into the Cat Paw image at docker build. Live probes of an owned host still prefer Latch when it is connected.
metadata:
  hermes:
    category: context
    tags: [image, gitleaks, semgrep, trivy, nmap, subfinder, nuclei, ffuf, latch, authorized-testing]
---

# Image tools

This Compose image **already has** the review and recon CLIs the pack
calls. They are installed at `docker build` from `vendor/review-tools.pin`,
on PATH as uid `hermes`. You do not `apt-get`, `go install`, or `pip install`
them at runtime. You do not tell the owner to install them on the laptop
just to run a scan.

**No permission in chat → no probe**, even with the binary sitting on PATH.

When Latch is connected, live packets at an owned target still go through
Latch (`plow-latch`): owner IP, approval card, evidence on disk. The
datacenter IP is the wrong IP for that. Use this image for static work,
public OSINT, and for agent-only installs (say out loud that the probe
is from the cloud).

Read this with `change-review`, `target-workspace`, and `cybersecurity-pack`.

## When to use

- "Do you have nmap / gitleaks / nuclei / subfinder?"
- First static gate on a paste, public PR diff, or workflow YAML
- You were about to install a scanner inside the container

## What is in PATH (baked)

Confirm with `/opt/cat-paw/verify-review-tools.sh`.

### Change review / supply chain

| CLI | Use it for |
| --- | --- |
| `gitleaks`, `trufflehog` | Secrets |
| `semgrep`, `bandit` | SAST |
| `trivy`, `grype`, `syft` | Image / fs / SBOM. Vuln DB is prefetched (`TRIVY_CACHE_DIR`) |
| `osv-scanner`, `snyk` | Lockfile SCA. `snyk` still needs `snyk auth` via Latch vault if they have an account |
| `checkov`, `kubesec`, `hadolint` | IaC / k8s / Dockerfile |
| `cosign`, `slsa-verifier` | Signatures / provenance |
| `gh`, `jq`, `yq`, `shellcheck` | Public PR metadata and parsing |

### Live recon (prefer Latch when connected)

| CLI | Use it for |
| --- | --- |
| `nmap`, `masscan`, `naabu` | Ports |
| `subfinder`, `amass`, `dnsx`, `dig`, `whois` | Names |
| `httpx` (`/opt/cat-paw/bin/httpx`, also `pd-httpx`) | HTTP probe. **Not** the Python HTTPX in the Hermes venv |
| `nuclei` | Templates at `/opt/cat-paw/nuclei-templates` (`-t` that dir) |
| `katana` | Crawl |
| `ffuf`, `gobuster`, `feroxbuster`, `dirb` | Content discovery. Wordlists under `/usr/share/wordlists/` and dirb's own |
| `dalfox` | XSS |
| `hashcat` | Cracking (CPU in this image, no GPU) |
| `sqlmap` | Extra yes — state-changing |
| Impacket (`secretsdump.py` / `impacket-secretsdump`) | AD — owned lab only |

Wordlists: `/usr/share/wordlists/common.txt`, `raft-small-words.txt`,
`raft-small-directories.txt`, `subdomains-top1million-5000.txt`,
`xato-net-10-million-passwords-10000.txt`, plus dirb's trees.

Already in the base image: `git`, `curl`, `rg`, `python3`, `node` / `npm` / `uv`.

If `command -v gitleaks` fails, this is not the Cat Paw Compose image.
Do not apt as root to "fix" a random Hermes. Rebuild this image.

## What is not in the image

| Tool | Why |
| --- | --- |
| Burp Suite, Ghidra | GUI. Use Latch on the owner's desktop if they have it. |
| Frida | Needs a USB/device lab, not this container. |
| Full SecLists / rockyou.txt | Too large. Curated lists are enough; say so if a playbook wants another file. |
| GPU OpenCL for hashcat | CPU only here. |

The 818 playbooks are still a **runtime clone** (`scripts/install-skills.sh`).
Tools ≠ playbooks.

## Where a scanner runs

```text
Paste / public PR diff / workflow YAML / public OSINT
  → this image
  → report on the phone
  → if Latch is connected, also write scans/ under the target workspace

Private repo / vault token / git over SSH
  → Latch fetch only. Do not clone secrets onto this disk.

Live host the owner named, browser, cookie, authenticated app
  → Latch when connected (correct IP + card)
  → this image only if Latch is down AND they accepted a cloud-IP probe
```

Durable evidence is still `~/CatPaw/workspaces/<slug>/` on the **device**.
`/tmp` and `/var/lib/hermes` are wiped with the volume.

## Commands

```text
gitleaks detect --no-git --source <dir> --report-format json --report-path -
semgrep --config p/ci --json <files>
trivy fs --scanners secret,misconfig,vuln --format json <dir>
osv-scanner scan --lockfile package-lock.json
nuclei -t /opt/cat-paw/nuclei-templates -u https://target.example
subfinder -d example.com
pd-httpx -u https://target.example -silent
nmap -sV -T4 example.com
ffuf -w /usr/share/wordlists/common.txt -u https://target.example/FUZZ
```

Do not:

- `curl | sh` a scanner installer
- `docker run` a scanner (no daemon in this image)
- clone a private repo onto `/var/lib/hermes`
- run `sqlmap` / `hashcat` / Impacket without an extra yes and owned scope
- write findings only under `/tmp` if Latch is up

## Existing Hermes (not this image)

`scripts/install-skills.sh --home` copies playbooks only. Rebuild on
Compose (`scripts/install.sh`) for these binaries.

## Failures

Missing binary after a rebuild: Discord draft in `plow-chat`. Destination:
https://watchmepivot.com/discord. No tokens.
