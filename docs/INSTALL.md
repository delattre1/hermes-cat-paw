# Install Hermes Cat Paw

This guide is for a Windows PC, Linux desktop, or Omarchy machine.

## 1. Install the device side

Hermes Cat Paw uses the [Cat Paw Latch fork](https://github.com/kumanaya/cat-paw-latch)
as its device-side control plane. Latch shows each proposed operation and the
owner approves it on the device.

On Windows, install Node.js 22+, Git, `just`, Python 3, and Visual Studio Build
Tools with the Desktop C++ workload. On Linux/Omarchy, install Node.js 22+, Git,
`just`, Python 3, a C++ toolchain, `bubblewrap`, and Secret Service support.

```sh
git clone https://github.com/kumanaya/cat-paw-latch.git
cd cat-paw-latch
just install
just app
```

Sign in inside Latch and leave it running so approval prompts remain visible.

## 2. Install the Hermes agent

```sh
git clone https://github.com/kumanaya/hermes-cat-paw.git
cd hermes-cat-paw
git clone https://github.com/plow-pbc/plow-agents.git ../plow-agents
export PATH="$PWD/../plow-agents/bin:$PATH"
plow-agents login --new-line
plow-agents lines
plow-agents mint <line-uid>
docker compose up --build -d
docker compose logs -f hermes-cat-paw
```

On Windows PowerShell, run the CLI through Python:

```powershell
python ..\plow-agents\bin\plow-agents login --new-line
python ..\plow-agents\bin\plow-agents lines
python ..\plow-agents\bin\plow-agents mint <line-uid>
```

`plow-credentials` is private. Never commit, print, or paste it.

### Already have Hermes?

Keep the existing Hermes home, persona, sessions, skills, provider settings, and
credentials. Install the official Plow Chat plugin for that Hermes version, then
configure the same launcher with:

```text
AGENT_ID=hermes-cat-paw
HERMES_HOME=<the existing Hermes home containing state.db>
```

The `AGENT_ID` variable alone does not report usage. Install the official Agent
Index client and run its reporter under the same supervisor that starts Hermes,
as the Hermes user, with the existing `PLOW_AGENT_TOKEN` supplied by the
credential manager or launcher. Never print or copy the token. Before changing a
persistent launcher, show the owner the proposed change and confirm that it
preserves the existing Hermes configuration.

## 3. Verify a safe first run

Text the Plow line:

> Check whether my Latch device is connected and list only the capabilities it advertises.

Then ask for one harmless visible action. The agent must inspect advertised
capabilities, choose the least-powerful matching tool, wait for approval, and
verify the result. A denial, timeout, disconnect, MFA request, or host block is
a stop signal — never bypass it or blindly retry an externally visible action.

## 4. Agent Index and usage

The image uses the official Agent Index client. With `AGENT_ID=hermes-cat-paw`,
the container registers the public page once and reports aggregate model-token
usage hourly. It does not send prompts, task text, files, paths, or secrets.

```sh
docker compose exec hermes-cat-paw /opt/hermes/.venv/bin/python3 /opt/plow/agent-index-client.py --self-check
docker compose exec hermes-cat-paw /opt/hermes/.venv/bin/python3 /opt/plow/agent-index-client.py --agent hermes-cat-paw --dry-run
```

Keep `hermes-cat-paw-home` between restarts; deleting it creates a new install
identity and splits the usage history. Check the [Agent Index](https://aiworthusing.com/agent-index)
after the next reporting cycle.

## Troubleshooting

- Latch does not open: run `just install` again and check native prerequisites.
- No agent response: inspect `docker compose logs hermes-cat-paw` and verify the credential.
- No ranking usage: check `AGENT_ID`, reporter logs, `--self-check`, and the persistent volume.
