$ErrorActionPreference = "Stop"

$Root = Split-Path -Parent $PSScriptRoot
$Tools = Join-Path $Root ".tools\plow-agents"
$Credentials = Join-Path $Root "plow-credentials"
$Cli = Join-Path $Tools "bin\plow-agents"

if (-not (Test-Path -LiteralPath $Credentials -PathType Leaf)) {
    if (-not (Test-Path -LiteralPath (Join-Path $Tools ".git"))) {
        New-Item -ItemType Directory -Force -Path (Split-Path -Parent $Tools) | Out-Null
        git clone https://github.com/plow-pbc/plow-agents.git $Tools
    }
    python $Cli login --new-line
    python $Cli lines
    $LineUid = Read-Host "Enter the free line UID to use"
    if ([string]::IsNullOrWhiteSpace($LineUid)) { throw "A line UID is required." }
    python $Cli mint $LineUid
} else {
    Write-Host "Using existing plow-credentials. Skipping Plow login."
}

$Compose = Join-Path $Root "compose.yml"
docker compose -f $Compose up --build -d
docker compose -f $Compose logs --tail=80 hermes-cat-paw
