[CmdletBinding()]
param(
    # Where to lay out the nine pinned checkouts. Defaults to a temp directory
    # so this never overwrites a developer workspace.
    [string]$TargetRoot = (Join-Path ([System.IO.Path]::GetTempPath()) 'eco-materialized'),

    # Delete an existing target first. Refuses to touch a tree that has commits
    # which no pin references.
    [switch]$Force
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$lock = Get-Content -Raw -Encoding utf8 -LiteralPath (Join-Path $root 'ecosystem.lock.json') | ConvertFrom-Json

if (Test-Path -LiteralPath $TargetRoot) {
    if (-not $Force) {
        throw "TargetRoot '$TargetRoot' already exists. Pass -Force to rebuild it."
    }
    Remove-Item -LiteralPath $TargetRoot -Recurse -Force
}

New-Item -ItemType Directory -Path $TargetRoot -Force | Out-Null

$token = $env:ECOSYSTEM_PAT
$failures = [System.Collections.Generic.List[string]]::new()

foreach ($project in $lock.projects) {
    $destination = Join-Path $TargetRoot $project.path
    New-Item -ItemType Directory -Path $destination -Force | Out-Null

    $remotePath = "$($project.repository).git"
    if (-not [string]::IsNullOrWhiteSpace($token)) {
        $remotePath = "x-access-token:$token@github.com/$remotePath"
    } else {
        $remotePath = "github.com/$remotePath"
    }

    Write-Host "Fetching $($project.id) @ $($project.revision)" -NoNewline

    # git warns on stderr routinely; do not let a warning abort the loop.
    $ErrorActionPreference = 'Continue'
    & git -C $destination init -q 2>$null | Out-Null
    & git -C $destination remote add origin "https://$remotePath" 2>$null | Out-Null

    # Fetch only the pinned object rather than the whole branch history.
    & git -C $destination fetch --quiet --depth 1 origin $project.revision 2>$null
    if ($LASTEXITCODE -ne 0) {
        & git -C $destination fetch --quiet --no-tags origin 2>$null
        if ($LASTEXITCODE -ne 0) {
            $ErrorActionPreference = 'Stop'
            $failures.Add("$($project.id): could not fetch $($project.repository); a private repository needs ECOSYSTEM_PAT")
            Write-Host ' FAILED' -ForegroundColor Red
            continue
        }
    }

    & git -C $destination checkout --quiet $project.revision 2>$null
    $ErrorActionPreference = 'Stop'
    if ($LASTEXITCODE -ne 0) {
        $failures.Add("$($project.id): fetched but could not check out $($project.revision)")
        Write-Host ' CHECKOUT FAILED' -ForegroundColor Red
        continue
    }

    $actual = (& git -C $destination rev-parse HEAD 2>$null).Trim()
    if ($actual -ne $project.revision) {
        $failures.Add("$($project.id): checked out '$actual' instead of the pinned '$($project.revision)'")
        Write-Host ' MISMATCH' -ForegroundColor Red
        continue
    }

    Write-Host ' ok' -ForegroundColor Green
}

if ($failures.Count -gt 0) {
    Write-Host "Materialization failed ($($failures.Count) issue(s)):" -ForegroundColor Red
    foreach ($failure in $failures) {
        Write-Host " - $failure" -ForegroundColor Red
    }
    exit 1
}

Write-Host "Pinned workspace materialized at $TargetRoot" -ForegroundColor Green