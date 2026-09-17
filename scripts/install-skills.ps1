# Load the pinned recon skill pack into a Hermes home. Default destination is
# the running Compose agent's /var/lib/hermes. Authorized testing only.
param(
    [string]$Home,
    [switch]$List
)

$ErrorActionPreference = "Stop"

$Root = Split-Path -Parent $PSScriptRoot
$Pin = Join-Path $Root "vendor\recon-skills.pin"
$Tools = Join-Path $Root ".tools\recon-skills"
$ComposeFile = Join-Path $Root "compose.yml"
$Service = "hermes-cat-paw"
$Segments = @("auth", "chains", "infra", "meta", "recon", "redteam")
$Docs = @("LICENSE", "SOUL.md", "AGENTS.md", "STYLE.md", "README.md")

$repo = $null
$sha = $null
Get-Content -LiteralPath $Pin | ForEach-Object {
    if ($_ -match '^repo=(.+)$') { $repo = $Matches[1].Trim() }
    if ($_ -match '^sha=(.+)$') { $sha = $Matches[1].Trim() }
}
if (-not $repo -or -not $sha) { throw "install-skills.ps1: malformed $Pin" }

if (-not (Test-Path -LiteralPath (Join-Path $Tools ".git"))) {
    Write-Host "install-skills.ps1: cloning recon-skills"
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $Tools) | Out-Null
    git clone $repo $Tools
    if ($LASTEXITCODE -ne 0) { throw "git clone failed" }
}
Write-Host "install-skills.ps1: checking out $sha"
git -C $Tools fetch origin $sha
if ($LASTEXITCODE -ne 0) { throw "git fetch failed" }
git -C $Tools checkout --detach $sha
if ($LASTEXITCODE -ne 0) { throw "git checkout failed" }
$got = (git -C $Tools rev-parse HEAD).Trim()
if ($got -ne $sha) { throw "install-skills.ps1: expected $sha, got $got" }

$n = @(Get-ChildItem -LiteralPath $Tools -Filter SKILL.md -Recurse -File).Count
Write-Host "install-skills.ps1: $n SKILL.md files at $sha"

if ($List) {
    Get-ChildItem -LiteralPath $Tools -Filter SKILL.md -Recurse -File |
        ForEach-Object { $_.FullName.Substring($Tools.Length + 1) } |
        Sort-Object
    return
}

$stage = Join-Path ([System.IO.Path]::GetTempPath()) ("recon-skills-" + [guid]::NewGuid().ToString("n"))
New-Item -ItemType Directory -Force -Path $stage | Out-Null
try {
    foreach ($name in ($Segments + $Docs)) {
        $from = Join-Path $Tools $name
        if (-not (Test-Path -LiteralPath $from)) { throw "missing $name in recon-skills checkout" }
        Copy-Item -LiteralPath $from -Destination (Join-Path $stage $name) -Recurse -Force
    }

    if ($Home) {
        $dest = Join-Path $Home "skills\recon-skills"
        New-Item -ItemType Directory -Force -Path $dest | Out-Null
        Copy-Item -Path (Join-Path $stage "*") -Destination $dest -Recurse -Force
        Write-Host "install-skills.ps1: wrote $dest ($n skills)"
        return
    }

    $id = docker compose -f $ComposeFile ps -q $Service 2>$null
    if (-not $id) {
        throw "install-skills.ps1: Compose agent is not running. Start it with scripts/install.ps1, or pass -Home HERMES_HOME."
    }

    Write-Host "install-skills.ps1: copying pack into the Compose agent"
    docker compose -f $ComposeFile exec -T -u 0 $Service mkdir -p /var/lib/hermes/skills/recon-skills
    if ($LASTEXITCODE -ne 0) { throw "mkdir recon-skills failed" }
    tar -C $stage -cf - @($Segments + $Docs) |
        docker compose -f $ComposeFile exec -T -u 0 $Service tar -C /var/lib/hermes/skills/recon-skills -xf -
    if ($LASTEXITCODE -ne 0) { throw "tar into container failed" }
    docker compose -f $ComposeFile exec -T -u 0 $Service chown -R hermes:hermes /var/lib/hermes/skills/recon-skills
    $landed = docker compose -f $ComposeFile exec -T -u hermes $Service sh -c 'find /var/lib/hermes/skills/recon-skills -name SKILL.md -type f | wc -l'
    Write-Host "install-skills.ps1: container pack has $($landed.Trim()) SKILL.md files"
    Write-Host "install-skills.ps1: authorized testing only. Live probes go through Latch."
}
finally {
    Remove-Item -LiteralPath $stage -Recurse -Force -ErrorAction SilentlyContinue
}
