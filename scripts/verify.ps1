# Confirm the Compose agent reports as hermes-cat-paw. Always exec the Index
# client as uid hermes — docker compose exec defaults to root and that breaks
# the sticky HERMES_HOME ledger.
$ErrorActionPreference = "Stop"

$Root = Split-Path -Parent $PSScriptRoot
$ComposeFile = Join-Path $Root "compose.yml"
$Service = "hermes-cat-paw"
$Python = "/opt/hermes/.venv/bin/python3"
$Client = "/opt/plow/agent-index-client.py"

function Invoke-Compose {
    docker compose -f $ComposeFile @args
    if ($LASTEXITCODE -ne 0) { throw "docker compose failed: $args" }
}

$id = docker compose -f $ComposeFile ps -q $Service 2>$null
if (-not $id) {
    throw "verify: container is not running. Start it with scripts/install.ps1."
}

Write-Host "verify: repairing Index ledger ownership (sticky HERMES_HOME)"
Invoke-Compose exec -T -u 0 $Service sh -c @'
  for f in /var/lib/hermes/.agent-index-state.json \
           /var/lib/hermes/.agent-index-state.json.new \
           /var/lib/hermes/.agent-index.json \
           /var/lib/hermes/.agent-index.lock; do
    [ -e "$f" ] || continue
    chown hermes:hermes "$f"
  done
  idf=/run/s6/container_environment/AGENT_ID
  if [ -r "$idf" ]; then
    got=$(cat "$idf")
    echo "verify: container AGENT_ID=$got"
    [ "$got" = "hermes-cat-paw" ] || exit 1
  fi
'@

Write-Host "verify: waiting for Hermes state.db"
$n = 0
do {
    docker compose -f $ComposeFile exec -T -u hermes $Service sh -c "test -s /var/lib/hermes/state.db"
    if ($LASTEXITCODE -eq 0) { break }
    $n++
    if ($n -gt 60) { throw "verify: state.db did not appear" }
    Start-Sleep -Seconds 2
} while ($true)

function Invoke-HermesClient {
    docker compose -f $ComposeFile exec -T -u hermes `
        -e HOME=/var/lib/hermes `
        -e HERMES_HOME=/var/lib/hermes `
        -e AGENT_ID=hermes-cat-paw `
        $Service $Python $Client @args
}

Write-Host "verify: Index client as uid hermes (never root)"
Invoke-HermesClient --self-check
if ($LASTEXITCODE -ne 0) { throw "verify: --self-check failed" }
Invoke-HermesClient status
$status = $LASTEXITCODE
Write-Host "verify: status exit $status (0=registered, 3=unregistered)"
if ($status -ne 0 -and $status -ne 3) { throw "verify: Index status failed ($status)" }
Invoke-HermesClient --agent hermes-cat-paw --dry-run
if ($LASTEXITCODE -ne 0) { throw "verify: --dry-run failed" }

Write-Host "verify: reporting current usage as hermes"
Invoke-HermesClient --agent hermes-cat-paw
if ($LASTEXITCODE -ne 0) { throw "verify: live report failed. Check docker compose logs hermes-cat-paw" }

Write-Host "verify: OK. Do not docker compose exec the Index client as root; use this script or -u hermes."
