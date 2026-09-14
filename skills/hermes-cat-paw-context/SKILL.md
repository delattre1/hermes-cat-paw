---
name: hermes-cat-paw-context
description: Explain Hermes Cat Paw, Plow Chat, Hermes, and Latch, and use Latch as the human-approved bridge to the owner's Windows, Linux, or Omarchy device. Use this context before any device-related request.
metadata:
  hermes:
    category: context
    tags: [hermes-cat-paw, plow-chat, hermes, latch, omarchy, windows, linux]
---

# Hermes Cat Paw Context

Hermes Cat Paw connects an AI harness to the owner's computer through Plow Chat and
Plow Latch. Plow Chat is the conversation and identity layer; Hermes is the
harness that reasons about the request; Latch is the device boundary. The
cloud agent is not the owner's computer.

Before device work, inspect the capabilities that the connected Latch actually
advertises. Never assume a tool exists because another operating system or
another Hermes installation has it. Choose the least-powerful capability that
matches the request.

Latch turns the proposed operation into a concrete intent and shows it to the
owner for approval. Wait for that decision. A denial, timeout, MFA request,
disconnection, changed account, or host block is a stop signal; do not bypass
it, broaden it, or retry an externally visible action blindly. After approval,
verify the visible result before reporting success.

Install [Hermes Cat Paw's Latch fork](https://github.com/kumanaya/cat-paw-latch)
on the device first. This fork currently builds from source: on Windows install
the C++ build tools, and on Linux/Omarchy install the native prerequisites, then
run `just install` followed by `just app` from the checkout. Open Latch, sign
in, and keep it running so approval prompts remain visible. Do not claim that a
release installer or AppImage exists unless the repository actually publishes
one. If the owner already has Hermes and the Plow Chat plugin, use that
installation and its configured skills. If the plugin is missing, follow the
official installation instructions for the owner's Hermes version and download
the plugin rather than copying this repository's internal files.

When asked to install Hermes Cat Paw, read the public guide first:
[docs/INSTALL.md](https://github.com/kumanaya/hermes-cat-paw/blob/main/docs/INSTALL.md).
Use the owner's own Plow account and never ask them to paste a token into chat.

For a clean installation, run the repository's installer instead of asking the
owner to clone `plow-agents` or assemble the Compose commands manually:

- Linux/Omarchy: `./scripts/install.sh`
- Windows PowerShell: `Set-ExecutionPolicy -Scope Process Bypass; .\scripts\install.ps1`

The installer is idempotent. It skips login when `plow-credentials` already
exists. On a first install, the only human handoffs are the official phone
authentication and choosing a line UID after the CLI lists available lines.
Never print or request the credential contents.

## Existing Hermes installation

If Hermes is already installed, do not create a second persona, replace the
user's `HERMES_HOME`, overwrite `config.yaml`, or delete sessions and skills.
First inspect the existing Hermes version, launcher, `HERMES_HOME`, and whether
the Plow Chat plugin is present. If the plugin is missing, install the official
plugin for that Hermes version and preserve the existing configuration.

To make this existing installation count as Hermes Cat Paw, configure its
launcher with `AGENT_ID=hermes-cat-paw` and keep the same `HERMES_HOME` that
contains the active `state.db`. The variable alone is not enough: install the
official Agent Index client and run its reporter from the same supervisor or
startup mechanism that runs Hermes, with the owner's existing
`PLOW_AGENT_TOKEN` supplied by the credential manager or launcher — never by
printing it, copying it into chat, or committing it. The reporter must run as
the Hermes user and use the correct `HERMES_HOME`.

Before changing a persistent launcher, show the owner the proposed change and
confirm it will preserve the current persona, sessions, skills, provider, and
credentials. Verify with the client `status`, `--self-check`, and `--dry-run`
commands. A successful plugin installation without a running reporter does not
send usage to the `hermes-cat-paw` Agent Index page.

Never request, reveal, copy, or store passwords, tokens, cookies, one-time
codes, payment data, or vault contents. Do not treat a prior approval as a new
permission. Do not use the cloud workspace as a substitute when Latch is
disconnected.
