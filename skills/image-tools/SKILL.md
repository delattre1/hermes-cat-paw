---
name: image-tools
description: Use when choosing where a scanner runs, asking what CLIs this agent has, installing gitleaks/semgrep/trivy/gh, or about to apt-get/nmap/subfinder inside Hermes. Lists tools baked into the Cat Paw image at docker build. Live probes still go through Latch.
metadata:
  hermes:
    category: context
    tags: [image, gitleaks, semgrep, trivy, gh, osv-scanner, latch, authorized-testing]
---

# Image tools

This Compose image **already has** the static-review CLIs `change-review`
needs. They are installed at `docker build` from `vendor/review-tools.pin`,
on PATH as uid `hermes`. You do not `apt-get`, `go install`, or `pip install`
them at runtime. You do not tell the owner to install them on the laptop
for a patch/snippet review.

Live packets at a target still go through **Latch** (`plow-latch`). Baking
`gitleaks` does not bake `nmap`. The datacenter IP is still the wrong IP.

Read this with `change-review` (what to scan), `target-workspace` (where
evidence lives), and `cybersecurity-pack` (which playbook).

## When to use

- "Do you have gitleaks / semgrep / trivy?"
- First static gate on a paste, public PR diff, or workflow YAML
- You were about to install a scanner inside the container
- You were about to run `nmap` / `subfinder` / `nuclei` from this image

**Do not use** as permission to probe a host. No written scope → no scan,
even with a binary sitting on PATH.

## What is in PATH (baked)

| CLI | Version pin | Use it for |
| --- | --- | --- |
| `gitleaks` | 8.30.1 | Secrets on a diff, snippet (`--no-git`), or public clone |
| `semgrep` | 1.177.0 | SAST on the files you already have |
| `trivy` | 0.74.0 | `fs --scanners secret,misconfig` on IaC/Dockerfile; vuln DB downloads on first `vuln` scan |
| `osv-scanner` | 2.6.0 | Lockfile / SCA. Open replacement for Snyk — no Snyk token in this image |
| `kubesec` | 2.14.2 | Kubernetes manifest score |
| `hadolint` | 2.15.1 | Dockerfile lint |
| `gh` | 2.101.0 | Public `gh pr view` / `gh pr diff`. Private repos: Latch + vault |
| `jq` | Debian | Parse scanner JSON |
| `yq` | 4.53.6 | Workflow / Helm / manifest YAML |
| `shellcheck` | Debian | Shell in the change |

Already in the base image (do not reinstall): `git`, `curl`, `rg`,
`python3` (Hermes venv), `node` / `npm` / `uv`.

Confirm with `/opt/cat-paw/verify-review-tools.sh` or `command -v gitleaks`.
If that fails, this is not the Cat Paw Compose image. Do not apt as root
to "fix" a random Hermes. Tell them to rebuild this image, or run the
scan on Latch.

## What is not in the image (on purpose)

| Tool | Why it is absent |
| --- | --- |
| `nmap`, masscan, naabu | Live network. Wrong IP from this cloud. Latch. |
| `subfinder`, amass, ProjectDiscovery `httpx`, nuclei, katana | Live recon + huge template/wordlist trees. Latch. |
| `ffuf`, gobuster, sqlmap | State-changing or noisy against a host. Latch, after an extra yes. |
| Snyk CLI | Needs their account. Use `osv-scanner`. |
| Burp, Ghidra, Frida, hashcat, Impacket | GUI, GPU, or AD live work. Not this container. |
| Cosign / syft / Checkov / Bandit | Overlap with trivy / semgrep / osv-scanner, or too heavy. |
| Wordlists, Trivy vuln DB, Semgrep rule packs | Stale the day we ship. First scan may download **rules/DBs**, not targets. |

`/opt/hermes/.venv/bin/httpx` is the **Python HTTPX** library, not
ProjectDiscovery `httpx`. Do not treat it as a port probe.

The 818 playbooks are still a **runtime clone** (`scripts/install-skills.sh`),
not baked. Tools ≠ playbooks.

## Where a scanner runs

```text
Paste / public PR diff / workflow YAML
  → this image, argv you would have shown on a Latch card
  → report on the phone
  → if Latch is connected, also write scans/ under the target workspace

Private repo / vault token / git over SSH
  → Latch fetch only. Do not clone secrets onto this disk.
  → Pipe the diff back (`git diff`, `gh pr diff`) and scan the patch here
  → Full-history gitleaks stays on the checkout (Latch). If the host
    has no gitleaks, say full-history was not tested; still scan the patch.

Live host, browser, cookie, nmap, subdomain enum
  → Latch only. Never from this image.
```

Durable evidence is still `~/CatPaw/workspaces/<slug>/` on the **device**
(`target-workspace`). `/tmp` and `/var/lib/hermes` are wiped with the
volume. Do not call a container path the report.

## Commands you may run here

Least power. No `network` at a customer origin. Registry / PyPI /
semgrep.dev / ghapi / osv.dev are OK for **tools**, not for the target.

```text
gitleaks detect --no-git --source <dir> --report-format json --report-path -
semgrep --config p/ci --json <files>
trivy fs --scanners secret,misconfig --format json <dir>
osv-scanner scan --lockfile package-lock.json
hadolint Dockerfile
kubesec scan deploy.yaml
gh pr diff N --repo owner/name
jq .
```

Do not:

- `nmap`, `masscan`, `subfinder`, `nuclei` — not installed; do not fetch them
- `curl | sh` a scanner installer
- `docker run` a scanner (no daemon in this image)
- `snyk auth`
- clone a private repo onto `/var/lib/hermes`
- write findings only under `/tmp` and call the job done if Latch is up

## Existing Hermes (not this image)

`scripts/install-skills.sh --home` copies playbooks only. It does not
install these binaries. Static gates then need Latch, or they rebuild
on Compose (`scripts/install.sh`).

## Failures

Missing binary after a rebuild: Discord draft in `plow-chat`. Destination:
https://watchmepivot.com/discord. No tokens.
