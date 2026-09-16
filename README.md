<p align="center">
  <img src="docs/images/banner.png" alt="Hermes Cat Paw" width="720" />
</p>

# Hermes Cat Paw

[![Agent Index](https://img.shields.io/badge/Agent%20Index-hermes--cat--paw-8bd5ca)](https://aiworthusing.com/agent-index/hermes-cat-paw)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

> **Install:** [docs/INSTALL.md](docs/INSTALL.md) · **Optional device:** [Cat Paw Latch](https://github.com/kumanaya/cat-paw-latch)

## Your AI can act. You stay in control.

Hermes Cat Paw gives your AI a voice you can reach from your phone and,
if you want it, a hand that can touch the computer you own.

**Plow Chat** is the conversation. **Hermes** is the mind that chooses a
skill and does the work. **Latch** is optional: the line between an
agent's intent and your actual device.

The agent can have a conversation without having a computer. It can have
capability without having silent permission.

> **Private by design.** Your Plow line belongs to you. Your Hermes skills
> remain yours. A device connection is yours to add, or to skip.

## Work from your phone. Keep control at your computer.

<p align="center">
  <img src="docs/images/workflow.png" alt="Hermes Cat Paw workflow from Plow Chat to your computer" width="760" />
</p>

You text from iMessage. Plow Chat carries the message. Hermes reasons
privately. If Latch is connected, the action waits on your machine —
visible, approved, then done.

The cloud agent is not your computer. Hermes Cat Paw keeps that boundary
in the open.

## Activate Plow Chat. Unlock your lines.

<p align="center">
  <img src="docs/images/lines.png" alt="Plow Chat unlocks named agent lines in iMessage" width="760" />
</p>

A Plow line is a named assistant already waiting on your account —
Willow, Aspen, Spruce, Elm, Alder. Activating Plow Chat unlocks them.
Hermes Cat Paw takes one that is still free and keeps it online.

You do not invent those agents. Plow Chat is what makes them reachable.

## Autonomy needs a brake.

<p align="center">
  <img src="docs/images/approve.png" alt="Approve an action on your computer" width="560" />
</p>

AI can click through a browser, run a command, and touch the systems
where your real life happens. The dangerous failure is not an agent that
cannot act. It is an agent that acts too confidently, too quickly, and
without you seeing what changed.

When you add Latch, approval becomes part of the work:

- **See the action before it happens.** Device work is a concrete intent, decided on your machine.
- **Approve the capability, not a vague promise.** Answer every time, or keep a rule for one exact, repeatable action.
- **A past "yes" is not a permanent yes.** A learned procedure is a hint. It never creates a new permission.
- **A stop is a stop.** Denial, timeout, MFA, a dropped connection, or a changed account ends the flow.
- **Verify, then report.** A successful tool call is not proof the outcome happened.

This is how automated work should feel: fast when it is safe, deliberate
when it matters.

## Security is not a checkbox.

The control plane lives on the device you own. The agent asks. You
decide. Nothing inbound is opened on your network.

| What is protected | How the boundary works |
| --- | --- |
| **Who is acting** | The relay authenticates the agent. Pending work and saved rules are scoped to that identity. |
| **What is allowed** | Acting operations pass a device-local capability decision and an approval policy. |
| **Where data lives** | Vault data stays on the device. The agent may request an approved use. It never reads a secret back into chat. |
| **How the device is reached** | Latch connects outbound to Plow. Credentials stay out of URLs and are redacted from logs. |
| **What changed** | Paths are canonicalized before approval. An append-only audit trail records the rest. |

On Windows and Linux, [Cat Paw Latch](https://github.com/kumanaya/cat-paw-latch)
adds native hardening — sandboxed command workspaces, presence checks,
and secrets that never leave the machine. A stop is a stop. The agent
does not route around it.

## Built for the desktop you actually use.

Chat works anywhere you can text the line. Device control follows the
Latch you run: upstream on macOS, the fork on Windows and Linux, with
[Omarchy](https://github.com/omacom/omarchy) as the reference desktop.

The context must discover what Latch advertises. It must never assume a
capability from another operating system is waiting here.

---

## Start here.

The full guide is [docs/INSTALL.md](docs/INSTALL.md). Pick a path —
agent only, Latch only, or both — and follow it.

```sh
git clone https://github.com/kumanaya/hermes-cat-paw.git
```

Then open the install guide. That is the whole next step.

---

**Real autonomy. Visible permission. Your computer stays yours.**

Hermes Cat Paw is MIT licensed. See [LICENSE](LICENSE).
