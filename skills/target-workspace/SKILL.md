---
name: target-workspace
description: Use before recon, pentest, PR review, snippet testing, or any Latch write. Creates and uses one ~/Plow/workspaces/<slug> folder per authorized target, with a fixed layout for scope, checkout, scans, reviews, reports. Do not dump evidence in /tmp or mix two targets.
metadata:
  hermes:
    category: context
    tags: [workspace, evidence, plow, latch, scope, authorized-testing]
---

# Target workspace

Every authorized target gets **one folder** on the owner's computer. Recon,
PR review, snippets, and scanner output all land there. Hermes does not
keep that tree in the cloud. Latch creates it under `~/Plow` so reads and
writes auto-approve unless the device is deny-all.

Read this **before** `change-review` or a pack hunt that would write a
file. If Latch is disconnected you may still name the slug in chat. You
may not claim the folder exists.

## When to use

- First message that names a host, repo, PR, gist, or snippet to work
- "Where did we put the gitleaks output?"
- Starting a second engagement on a target you already opened
- Any time you were about to write `~/Plow/reviews/…`, `/tmp`, or `./output`

**Do not use** to scan a target that has no permission in this thread.
No permission → no folder → no probe.

## One target, one slug, one tree

```text
~/Plow/workspaces/
  INDEX.md                         # list of slugs (no secrets)
  <slug>/
    TARGET.md                      # identity, permission, stop
    scope/                         # what's in / out, written auth notes
    intake/                        # why this engagement started
    checkout/
      owned/                       # git clones the owner already trusts
      untrusted/                   # fork PRs, foreign gists (read-only default)
    diffs/                         # saved patches, name-only lists
    scans/
      secrets/
      sast/
      sca/
      iac/
      recon/
      web/
    artifacts/                     # screenshots, HAR, pcaps — not vault values
    reviews/                       # one subfolder per PR or snippet
    reports/                       # REPORT.md, dated copies
    logs/                          # command transcripts, redacted
    tmp/                           # disposable; ok to delete
```

`OUTPUT_DIR` for pack skills is this tree (usually `scans/…` or
`reports/`). Never `${OUTPUT_DIR:-./output}` on a random cwd.

## Slug

Derive from the **target they named**, not from the chat title.

| They named | Slug |
| --- | --- |
| `app.example.com` | `app-example-com` |
| `https://github.com/acme/web` | `acme-web` |
| PR on that repo | still `acme-web` (PR goes under `reviews/pr-12`) |
| Paste with no repo | `snippet-<utc>` (example `snippet-20260917t193000z`) |
| `192.168.10.4` (owned lab) | `192-168-10-4` |

Rules:

- Lowercase ASCII. `[a-z0-9]` and hyphens only.
- Collapse `github.com/`, `http://`, `https://`, trailing slashes.
- Max 64 characters. If longer, keep the distinctive tail (repo name,
  registrable domain), not the path junk.
- No leading dot, no spaces, no `#`, no tokens, no email local-parts.
- Do not encode the phone number, line name, or agent uid in the path.

If two names slug to the same string and they are **not** the same
target, stop and ask. Do not reuse a folder for a different host.

## Create (Latch, first time)

1. Confirm permission in chat (owned or written).
2. Compute the slug. Say it on the phone.
3. `plow_read_file` `~/Plow/workspaces/<slug>/TARGET.md`. If it exists,
   **reuse** — do not mkdir a second tree. Append the new engagement
   under `reviews/` or `intake/`.
4. If missing, create the layout in **one** command (smallest argv).
   `write_paths` includes `~/Plow/workspaces`. No `network`.

```text
python3 -c "import os, pathlib; root=pathlib.Path.home()/'Plow'/'workspaces'/'SLUG';
subs=['scope','intake','checkout/owned','checkout/untrusted','diffs',
'scans/secrets','scans/sast','scans/sca','scans/iac','scans/recon','scans/web',
'artifacts','reviews','reports','logs','tmp'];
[(root/s).mkdir(parents=True, exist_ok=True) for s in subs]"
```

Replace `SLUG` with the real slug. Then `plow_write_file` `TARGET.md`
and a one-line append to `~/Plow/workspaces/INDEX.md`.

`TARGET.md` (no secrets):

```text
slug: acme-web
name: github.com/acme/web
kind: repo
permission: owned
created: 2026-09-17T19:30:00Z
stop: no production, no force-push
notes: PR review and later staging recon share this folder
```

`kind` is `host` | `repo` | `snippet` | `other`. `permission` is `owned`
| `written`. Anything else: delete nothing; do not scan; ask.

## Where each kind of work goes

| Work | Path under the slug |
| --- | --- |
| Scope / out-of-scope | `scope/SCOPE.md` |
| Chat decisions worth keeping | `intake/` (redact) |
| Clone of an owned repo | `checkout/owned/<repo>/` |
| Fork PR checkout | `checkout/untrusted/pr-<n>/` |
| Pasted snippet | `reviews/snippet-<utc>/input` |
| `git diff` / `gh pr diff` | `diffs/` |
| Gitleaks, Semgrep, Trivy, nmap, subfinder | matching `scans/…` |
| Screenshots, HAR | `artifacts/` |
| Per-PR writeup | `reviews/pr-<n>/NOTES.md` |
| Engagement report | `reports/REPORT.md` (and `reports/<utc>.md` if you rotate) |
| Command logs | `logs/` |
| Junk | `tmp/` only |

Do not:

- Clone into `~/`, `~/Downloads`, `/tmp`, or the Hermes cloud home
- Put scanner JSON in `checkout/`
- Put a live `.env` or private key in `artifacts/` — vault + rotate
- Mix `app.example.com` evidence into `acme-web` because they "feel related"
- `rm -rf` another slug. `tmp/` inside **this** slug is the only thing
  you may wipe without asking

Untrusted trees stay in `checkout/untrusted/`. `change-review` still
requires an explicit yes before `npm install` / tests there.

## INDEX.md

Keep `~/Plow/workspaces/INDEX.md` as a table the owner can open:

```text
# Workspaces

| slug | name | kind | permission | opened |
| --- | --- | --- | --- | --- |
| acme-web | github.com/acme/web | repo | owned | 2026-09-17 |
```

Append a row on first create. Do not list findings. Do not list secrets.

## Reuse

Same target later (more recon, another PR):

1. Read `TARGET.md`. If `permission` is still valid, continue.
2. New PR → `reviews/pr-<n>/`, new clone only if `checkout/owned/` is
   missing or they asked to refresh.
3. Update `reports/REPORT.md`; do not start a parallel `~/Plow/reviews/`.

If they renamed the product or moved the repo, ask whether this is the
same target. Slug changes only when they say so; then copy, don't fork
silently.

## Phone vs disk

Phone (no tables, no fences): slug, folder path in words, permission,
what you created vs reused.

Disk holds the tree. Latch's audit log is not a substitute for
`reports/REPORT.md`.

## Stops

| Situation | What you do |
| --- | --- |
| No permission in chat | No folder |
| Slug collision with a different target | Ask; do not write |
| `TARGET.md` says a stop that this ask would break | Stop |
| Latch disconnected | Do not pretend the workspace is on this cloud |
| They ask to delete a workspace | Confirm the slug, then only that tree |

## Failures

If mkdir / write fails, use the Discord draft in `plow-latch`. Never
print vault values. Destination: https://watchmepivot.com/discord
