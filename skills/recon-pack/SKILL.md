---
name: recon-pack
description: Use for authorized recon, pentest, bug bounty, subdomain enumeration, web/API hunting, XSS/SQLi/SSRF validation, cloud pivots, and security reporting. Explains the uphiago/recon-skills pack, when Latch must run the live probes, and that unauthorized targets are out of scope.
metadata:
  hermes:
    category: context
    tags: [recon, pentest, bug-bounty, latch, authorized-testing]
---

# Recon pack

This agent ships a **segment skill pack** for authorized security testing:
[uphiago/recon-skills](https://github.com/uphiago/recon-skills) (MIT). It is
not a license to scan the internet. Only test targets the owner **owns** or
has **written permission** to test. If that is missing, refuse and ask.

The playbooks land at `skills/recon-skills/` after `scripts/install-skills.sh`
(Windows: `install-skills.ps1`). If that tree is missing, tell the owner to
run the installer. Do not invent procedures from memory.

## Segments

| Directory | Use it for |
| --- | --- |
| `recon-skills/recon/` | Discovery: subdomains, ports, HTTP, JS, APIs |
| `recon-skills/auth/` | Authentication and SSO |
| `recon-skills/infra/` | Cloud, containers, exposed infrastructure |
| `recon-skills/redteam/` | Vulnerability-class and platform playbooks, reporting |
| `recon-skills/chains/` | Evidence-backed attack paths |
| `recon-skills/meta/` | Engagement planning, recon playbook |

Entry points (read the `SKILL.md` in the same turn, then follow it):

- `meta/recon-playbook`
- `redteam/bb-methodology`
- `redteam/web2-recon`
- `recon/subdomain-enumeration`
- `recon/web-enumeration`
- `recon/js-secrets-extraction`
- `chains/cross-attack-chains`
- `redteam/triage-validation`
- `redteam/evidence-hygiene`
- `redteam/report-writing`

SOUL.md / STYLE.md in that tree are the pack's operating rules. They win over
improvisation.

## Latch is the probe surface

You reason in the cloud. The owner's computer is where recon **runs**.

- Live web, JS bundles, authenticated app flows → `plow_browser_open` (see
  `plow-latch`). Datacenter `fetch` hits bot walls and is the wrong IP.
- `nmap`, `curl`, wordlists, local parsers → `plow_run_command` after the
  owner approves. Prefer `~/Plow` / `${OUTPUT_DIR:-./output}` on **their**
  machine for artifacts.
- Secrets (bounty platform cookies, API tokens) stay in the Latch vault.
  Fill with `fill_secret`. Never paste them into chat.
- A `pending` handle is an approval card. Poll `plow_get_result`. Do not
  re-issue. `denied`, timeout, `blocked`, or disconnect is a stop.

Without Latch, you may still plan, read the pack, and draft a report. You
may not claim you probed a host from this cloud workspace.

## How to work a target

1. Confirm scope and permission in this chat.
2. Read `plow-latch`, then `plow_list_skills` on the connected device.
3. Read the matching pack skill. Follow its prerequisites and gates.
4. Distinguish discovery from validation. Do not fire a state-changing
   request until the owner confirms.
5. Verify with semantic evidence (the pack's Verification section). A
   status code is not a finding.
6. Write evidence under the owner's output dir. Redact. Report.

If a tool fails, use the Discord report block in `plow-latch` /
`plow-chat`. Do not work around Latch.
