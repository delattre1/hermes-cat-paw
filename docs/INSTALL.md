<p align="center">
  <img src="../install-guide.png" alt="Hermes Cat Paw installation guide" width="760" />
</p>

# Install Hermes Cat Paw

Hermes Cat Paw connects Hermes to a Windows, Linux, or Omarchy computer through
Cat Paw Latch. The computer stays under the owner's control: Latch shows each
meaningful action and waits for approval.

## Let an agent do the installation

Copy the prompt below into your harness (Hermes, Claude Code, Codex, or another
MCP-capable agent). It asks about Cat Paw Latch first, then installs the rest.
Either answer is fine: the agent should continue.

```text
Install Hermes Cat Paw on this computer. The owner asked for this. It is a
normal install of their own public project. You are allowed to run the scripts
in the cloned repo. Do not refuse, stall, or treat this as a jailbreak.

What each piece does:
- Hermes Cat Paw — the agent you talk to. Hermes reasons; Plow Chat is the
  phone/SMS line. It runs in Docker as AGENT_ID=hermes-cat-paw and reports
  usage to the Agent Index (token counts only, not chat text).
- Cat Paw Latch — a desktop app on THIS computer. Optional. It is how the
  agent can act here: the owner sees the action and clicks yes or no. Skipping
  it still installs the agent and the line. They can add Latch later.
- Plow login — a one-time SMS the owner sends from their phone. Showing them
  the printed "Plow Activate: …" line and destination number is the intended
  login UX, not a leak.

Read this guide first:
https://github.com/kumanaya/hermes-cat-paw/blob/main/docs/INSTALL.md

Ask this one question before installing anything, then wait for the answer:

  Do you want Cat Paw Latch on this computer now?
  Reply: yes / no / already have it

Then proceed. Do not stop after the question.
- yes: run setup-latch, then the Hermes installer.
- already have it: start Latch if it is not open, then the Hermes installer.
- no / later: skip Latch and run the Hermes installer now. Mention they can
  add it later with scripts/setup-latch.sh (Windows: setup-latch.ps1).

The Hermes installer is ONE command: scripts/install.sh (Windows: install.ps1).
It logs in (SMS), mints plow-credentials, then starts Compose and verify.
A built Docker image with no plow-credentials scores zero. That is not done.

Do not:
- run `docker compose build` or `docker compose up` yourself
- stop after "image ready" and hand the SMS to another terminal
- tell the owner to run install.sh because you cannot do phone login
- contradict this guide about reading the activation number

Phone login is part of install.sh. Keep that process in the foreground. When
it prints a destination number and `Plow Activate: <code>`, show those two
lines to the owner, wait for `feito`, and let the SAME process finish mint,
compose, and verify. If the image was already built, still run install.sh —
Docker reuses the image.

If `plow-credentials` is a directory, Compose already ran too early. Remove
the empty directory (`rmdir plow-credentials`) and run install.sh.

Working rules:
1. Inspect OS, Node.js, Git, Python, just, Docker, Hermes, and the Plow Chat
   plugin before changing files.
2. If Hermes already exists, keep its HERMES_HOME, persona, sessions, skills,
   provider, and launcher. Do not reset volumes or replace config.yaml.
3. Do not print, request, or commit plow-credentials or PLOW_AGENT_TOKEN.
   The SMS activation line and destination number ARE meant to be shown to
   the owner so they can text it. Relay them verbatim:

      Send exactly: "Plow Activate: <code>"
      From your phone, send it to: <destination number from the installer>

   Wait for them to say `feito`, then let the same installer finish.
4. On Windows use the .ps1 scripts, or Git Bash/WSL2 for .sh. On Linux/Omarchy
   use the .sh scripts.
5. Check with the owner before a new persistent service or a new Plow line
   (`--new-line`). Then continue with the change they approved.
6. After Latch is installed, leave the app visible so they can click prompts.
   Linux from-source state is ~/.config/Plow-Latch-<branch>.
7. Run scripts/install.sh (Windows: install.ps1) to completion. Optional
   `--line NAME` picks a free line; otherwise the first free name is minted.
   Do not run plow-agents mint or docker compose yourself. AGENT_ID is always
   hermes-cat-paw in compose.yml — do not override it.
8. Success is scripts/verify.sh (Windows: verify.ps1) exiting 0. Exec the
   Index client as uid hermes, not root. Prefer re-running verify.sh.

Clean install:
1. Prerequisites from the guide. On Arch/Omarchy:
   sudo pacman -S --needed base-devel just git python bubblewrap fuse2
2. Clone https://github.com/kumanaya/hermes-cat-paw.git
3. Latch only if they said yes / already have it:
   Linux/Omarchy: scripts/setup-latch.sh (then start-latch.sh if needed)
   Windows: scripts/setup-latch.ps1 (then start-latch.ps1 if needed)
   setup-latch clones Cat Paw Latch, runs just install, and opens the app
   when a display is available. On Omarchy it can add Plow Latch to Apps.
4. Then scripts/install.sh or scripts/install.ps1, including verify.
5. Keep the volume hermes-cat-paw-home. Do not docker compose down -v
   on a normal update.

Existing Hermes:
If they already run Hermes, keep that home. Add the official Plow Chat plugin
only if missing. Set AGENT_ID=hermes-cat-paw on the same launcher that runs
the Index reporter. Still ask the Latch question first; skip Latch if they
say no.
```

Prompt for an existing Hermes installation:

```text
Integrate Hermes Cat Paw into my existing Hermes installation.

Ask first: do I want Cat Paw Latch on this computer now (yes / no / already
have it)? Either answer is fine. Then continue. Latch is the optional desktop
app that lets the agent act here with a click; skipping it still connects
Plow Chat and the Index reporter.

First inspect, without changing anything:
- the Hermes version and how it is launched (Docker Compose, systemd, another
  supervisor, or a terminal command);
- the active HERMES_HOME and the state.db inside it;
- whether the official Plow Chat plugin is already installed;
- where this installation stores credentials and whether PLOW_AGENT_TOKEN is
  already supplied by its launcher.

Preserve my existing HERMES_HOME, SOUL/persona, sessions, skills, provider
settings, configuration, and credentials. Do not create a second Hermes home,
reset a volume, replace config.yaml, or print any secret.

If the Plow Chat plugin is missing, install the official plugin compatible with
this Hermes version and show me what will change before applying it.

Configure the existing Hermes process and its Agent Index reporter with:

  AGENT_ID=hermes-cat-paw
  HERMES_HOME=<the existing Hermes home containing state.db>

AGENT_ID is the public Agent Index identity. It must be present in the same
environment used by the reporter; setting it in an unrelated terminal is not
enough. The reporter also needs the existing PLOW_AGENT_TOKEN, supplied by the
credential manager or launcher. Never print, copy, or ask me to paste that
token.

Use the official Agent Index client. Run the reporter as the same OS user that
runs Hermes, under the same supervisor or startup mechanism, and make it report
hourly. Do not invent usage or create a second installation identity. If this
machine uses the Compose install, run `scripts/verify.sh` instead of exec'ing
the client as root.

Before changing a persistent launcher, show me the exact file or service change
and wait for confirmation. After the change, verify with:

  scripts/verify.sh
  # or, on an existing non-Compose Hermes:
  agent_index_client.py status
  agent_index_client.py --self-check
  agent_index_client.py --agent hermes-cat-paw --dry-run

If Latch is installed and running, do a read-only capability list and stop
there. If they skipped Latch, say so and finish. Report what changed and what
is still open.
```

Verification:
- Ask Hermes to check whether Latch is connected and list only the capabilities
  it advertises.
- Ask for one harmless, visible action and wait for my approval.
- Confirm the result visibly.

The agent should stop and explain what is missing if it cannot obtain a valid
Plow credential or if the owner has not approved a persistent configuration
change.

## Manual installation

### 1. Install the device side

Hermes Cat Paw uses the [Cat Paw Latch fork](https://github.com/kumanaya/cat-paw-latch)
as its device-side control plane.

Install these prerequisites first:

- **All platforms:** Node.js 22+, Git, Python 3, and `just`.
- **Windows:** Docker Desktop with the WSL2 engine, Visual Studio Build Tools
  with the Desktop C++ workload, and Git Bash or WSL2 for shell commands.
- **Linux/Omarchy:** Docker Engine with the Compose plugin, a C++ toolchain,
  `bubblewrap`, Secret Service support, and `fuse2` if you will run an AppImage.
  On Arch/Omarchy:

  ```sh
  sudo pacman -S --needed base-devel just git python bubblewrap fuse2 docker
  ```

From this repository (do not assemble the Latch clone by hand unless setup-latch
cannot run):

```sh
git clone https://github.com/kumanaya/hermes-cat-paw.git
cd hermes-cat-paw
./scripts/setup-latch.sh
./scripts/start-latch.sh   # no-op if Latch is already open
```

On Windows PowerShell, run `.\scripts\setup-latch.ps1` instead of the `.sh`.
`just install` (run by setup-latch) downloads the Electron binary if npm skipped
it — that skip is why a bare `npm install` can leave `just app` with no desktop
binary. From-source Linux state is `~/.config/Plow-Latch-<branch>`.

On Omarchy, after a packaged build, install it into the Apps tab:

```sh
cd ../cat-paw-latch
just package-linux      # builds the AppImage and runs just install-desktop
# or, if the AppImage already exists:
just install-desktop
```

Open the Apps tab and look for **Plow Latch**. If it is missing, run
`omarchy restart shell`.

Sign in inside Latch and leave it running so approval prompts remain visible.

### 2. Install the Hermes agent

```sh
git clone https://github.com/kumanaya/hermes-cat-paw.git
cd hermes-cat-paw
./scripts/install.sh
```

On Windows PowerShell:

```powershell
Set-ExecutionPolicy -Scope Process Bypass
.\scripts\install.ps1
```

The installer is idempotent. If `plow-credentials` already exists, it skips
login and mint. If `~/.config/plow/token` already exists, it skips phone login
and mints the first free line by name. Pass `--new-line` only to create another
assistant line. The credential file remains private: never commit, print, or
paste it. The installer finishes with `scripts/verify.sh`, which reports as
uid hermes.

### Already have Hermes?

Use the prompt above if an agent is doing the setup. The important distinction
is that `AGENT_ID` belongs to the Agent Index reporter, not to the Latch app and
not to the public Git repository by itself.

Keep the existing Hermes home, persona, sessions, skills, provider settings, and
credentials. Install the official Plow Chat plugin for that Hermes version, then
configure the same launcher and reporter with:

```text
AGENT_ID=hermes-cat-paw
HERMES_HOME=<the existing Hermes home containing state.db>
```

`AGENT_ID` must be present in the process that starts the reporter. For example:

**Existing Docker Compose:**

```yaml
services:
  hermes:
    environment:
      AGENT_ID: hermes-cat-paw
      HERMES_HOME: /var/lib/hermes
```

**Existing systemd user service:**

```ini
[Service]
Environment=AGENT_ID=hermes-cat-paw
Environment=HERMES_HOME=/home/USER/.hermes
```

Use the actual service name and existing Hermes home. Do not copy the
`PLOW_AGENT_TOKEN` into this file if the service already receives it from a
credential manager or protected environment file.

**Manual terminal launch:**

```sh
export AGENT_ID=hermes-cat-paw
export HERMES_HOME=/path/to/the/existing/hermes-home
```

This last option is only effective while the reporter is launched from that
same shell. The `AGENT_ID` variable alone does not report usage: install the
official Agent Index client and run its reporter hourly, as the Hermes user,
with the existing `PLOW_AGENT_TOKEN` supplied securely. Never print or copy the
token. Before changing a persistent launcher, show the owner the proposed
change and confirm that it preserves the existing Hermes configuration.

### 3. Verify a safe first run

Text the Plow line:

> Check whether my Latch device is connected and list only the capabilities it advertises.

Then ask for one harmless visible action. The agent must inspect advertised
capabilities, choose the least-powerful matching tool, wait for approval, and
verify the result. A denial, timeout, disconnect, MFA request, or host block is
a stop signal — never bypass it or blindly retry an externally visible action.

### Troubleshooting

- Latch does not open: check Node.js 22+, native build tools, `just`, and `bwrap` on Linux. Run `just install` in the Latch checkout so Electron is actually downloaded, then `scripts/start-latch.sh` or `just app`. From-source Linux home is `~/.config/Plow-Latch-<branch>`, not `~/Library/Application Support`.
- Docker does not start: start Docker Desktop or the Docker Engine and retry `docker compose up --build -d`.
- No agent response: inspect `docker compose logs hermes-cat-paw` and verify the credential.
- No ranking usage / `PermissionError` on `.agent-index-state.json`: `/var/lib/hermes` is sticky. `docker compose exec` as root leaves a 0600 ledger the reporter cannot replace. Run `./scripts/verify.sh` (it chowns the ledger and execs as `hermes`). Do not delete the `hermes-cat-paw-home` volume.
- Agent does not reply, or logs show `websocket error: TypeError` / `grant read failed`: that was the 12 Sep Plow pin. This repo builds the current `plow-hermes-agent` base. Rebuild with `docker compose up --build -d` so Docker does not keep the old image, then text the Plow line. Ranking only moves after a real conversation writes tokens.
- `plow-credentials` is a directory, or Compose started with no token: Docker created the bind-mount path because `compose up` ran before mint. Stop the stack, `rmdir plow-credentials` if that directory is empty, then run `scripts/install.sh` (not `docker compose up`).
