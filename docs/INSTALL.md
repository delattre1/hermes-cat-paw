<p align="center">
  <img src="../install-guide.png" alt="Hermes Cat Paw installation guide" width="760" />
</p>

# Install Hermes Cat Paw

Hermes Cat Paw connects Hermes to a Windows, Linux, or Omarchy computer through
Cat Paw Latch. The computer stays under the owner's control: Latch shows each
meaningful action and waits for approval.

## Let an agent do the installation

Copy the prompt below into your harness (Hermes, Claude Code, Codex, or another
MCP-capable agent). It is intentionally explicit so the agent can inspect the
machine, preserve an existing Hermes installation, and stop safely when a
credential or owner decision is required.

```text
Install and configure Hermes Cat Paw on this computer.

Goal:
- Connect my Hermes agent to my Windows, Linux, or Omarchy computer through
  Cat Paw Latch.
- Use the public agent identity AGENT_ID=hermes-cat-paw.
- Keep my existing Hermes installation intact if one already exists.
- Make the installation report usage to the Agent Index without exposing any
  secret or sending prompts, files, paths, or task content.

Read this guide first:
https://github.com/kumanaya/hermes-cat-paw/blob/main/docs/INSTALL.md

Safety rules:
1. Inspect the OS, architecture, installed Node.js, Git, Python, just, Docker,
   Hermes, and the Plow Chat plugin before changing anything.
2. If Hermes already exists, preserve its HERMES_HOME, persona, sessions,
   skills, provider settings, credentials, and launcher. Do not delete files,
   reset volumes, replace config.yaml, or create a second persona.
3. Never print, request, paste, commit, or send passwords, tokens, cookies,
   plow-credentials, or PLOW_AGENT_TOKEN in chat or logs. The temporary
   `Plow Activate: <code>` message and destination number printed by
   `plow-agents login` are safe activation instructions and must be relayed to
   me verbatim so I can complete the phone verification.
4. Use the official Plow tooling and plugin for the installed Hermes version.
   Do not clone or copy private credentials into this repository.
5. On Windows, use Git Bash or WSL2 for commands that need sh/bash. Do not
   assume PowerShell can run Unix shell commands.
6. Ask me before a persistent launcher/service change, a new Plow line, or any
   action that could replace existing Hermes state. Explain the exact change.
7. Keep Latch running and visible. After `scripts/setup-latch.sh`, run
   `scripts/start-latch.sh` if the app is not already open. For the first
   device check, use only a read-only capability check. Never bypass an
   approval, denial, timeout, MFA, disconnect, or host block. On
   Linux/Omarchy, Latch from-source state lives in ~/.config/Plow-Latch-<branch>,
   not ~/Library/Application Support.
8. During `plow-agents login`, read the installer output. When it prints a
   destination number and an activation message, immediately return both to me
   in chat. Use this format:

      Send exactly: "Plow Activate: <code>"
      From your phone, send it to: <destination number shown by the installer>

   Do not tell me to look at the terminal and do not invent or omit the number.
   Wait for me to confirm `feito` after sending the SMS, then continue waiting
   for the installer to finish. Do not claim login success before it finishes.
9. Run `scripts/install.sh` (Linux/Omarchy) or `scripts/install.ps1` (Windows)
   and let that one command finish. You may pass `--line NAME` / `-Line NAME`
   to select a free line (Willow, Aspen, …). Occupied lines are not valid.
   With no `--line`, the installer mints the first free name. Do not run
   `plow-agents mint` or `docker compose` yourself. Never set, override, or
   ask me to paste AGENT_ID: it is always `hermes-cat-paw` in compose.yml.
   Pass `--new-line` / `-NewLine` only after I confirm I want another number.
   During phone login, relay the SMS as in rule 8, wait for `feito`, then let
   the same installer process start Compose. Confirm the container env is
   AGENT_ID=hermes-cat-paw. Keep troubleshooting until it is. Do not stop
   after explaining a command for me to run manually.
10. The installer ends with `scripts/verify.sh` (Windows: `verify.ps1`). That
    is the success check: Index client as uid hermes, ledger writable, usage
    report attempted. Do not `docker compose exec` the Index client as root.
    `/var/lib/hermes` is sticky; a root-owned `.agent-index-state.json` makes
    the hourly reporter fail with PermissionError and ranking stays at zero.
    If you must exec by hand, use `-u hermes` and HOME=/var/lib/hermes. Prefer
    re-running `scripts/verify.sh`. Do not claim the install works until
    verify exits 0.

Clean installation:
1. Install the prerequisites for this OS: Node.js 22+, Git, Python 3, just,
   Docker with Compose, and the platform-native build dependencies described
   in this guide. On Arch/Omarchy also install `base-devel`, `bubblewrap`,
   and `fuse2` (`sudo pacman -S --needed base-devel just git python bubblewrap fuse2`).
2. Clone https://github.com/kumanaya/hermes-cat-paw.git. From that checkout
   run `scripts/setup-latch.sh` on Linux/Omarchy (or `scripts/setup-latch.ps1`
   on Windows). That clones Cat Paw Latch next to this repo if needed, runs
   `just install` (which downloads Electron when npm skipped the binary), and
   launches Latch when a display is available (`scripts/start-latch.sh`). If
   Latch did not open, run `scripts/start-latch.sh` or `just app` from the
   Latch checkout in a visible terminal. On Omarchy, if a packaged AppImage
   exists, `setup-latch` also runs `just install-desktop` so Plow Latch appears
   in the Apps tab. Sign in and leave it running. Do not stop after printing
   the clone commands.
3. Run `scripts/install.sh` on Linux/Omarchy or `scripts/install.ps1` on
   Windows and let it finish, including its verify step. Optional `--line NAME`
   selects a free line; otherwise the first free name is minted. Do not mint
   or start Compose by hand. If an account token already exists it skips phone
   login; if `plow-credentials` already exists it skips mint. Compose always
   starts with AGENT_ID=hermes-cat-paw; do not override it from the host
   environment. It does not create a new line unless `--new-line` / `-NewLine`
   is passed after I confirm. During phone login, relay the exact activation
   message and destination number printed by the installer; do not make the
   user search the terminal.
4. Keep the named volume `hermes-cat-paw-home`; never use `docker compose down
   -v` during a normal update. Re-run `scripts/verify.sh` after any compose
   restart.

Existing Hermes installation:
1. Install the official Plow Chat plugin for the detected Hermes version only
   if it is missing.
2. Configure the existing Hermes launcher with AGENT_ID=hermes-cat-paw and
   the existing HERMES_HOME containing state.db.
3. Install the official Agent Index client and run its reporter as the Hermes
   user from the same supervisor that starts Hermes. Supply the existing
   PLOW_AGENT_TOKEN through the credential manager or launcher, never by
   printing it. AGENT_ID alone is not enough to report usage.
4. Validate with the client's `status`, `--self-check`, and `--dry-run` without
   sending private data. Do not claim success until the reporter is actually
   configured.
```

Prompt for an existing Hermes installation:

```text
Integrate Hermes Cat Paw into my existing Hermes installation.

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

Finally, perform only a read-only Latch capability check and stop for my
approval before any device action. Report exactly what was changed and what
remains unconfigured.
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
