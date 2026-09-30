[CmdletBinding()]
param(
    # Ask the GitHub API whether every revision pinned in ecosystem.lock.json
    # actually exists in the repository it is pinned from. Catches invented,
    # truncated, or force-pushed-away pins that a local clone cannot reveal.
    [string]$RepositoryFilter
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$lockPath = Join-Path $root 'ecosystem.lock.json'

if (-not (Test-Path -LiteralPath $lockPath)) {
    Write-Host "Missing $lockPath" -ForegroundColor Red
    exit 1
}

$lock = Get-Content -Raw -Encoding utf8 -LiteralPath $lockPath | ConvertFrom-Json
[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

$token = $env:ECOSYSTEM_PAT
if ([string]::IsNullOrWhiteSpace($token)) {
    $token = $env:GITHUB_TOKEN
}

$headers = @{
    'Accept'     = 'application/vnd.github+json'
    'User-Agent' = 'eco-consistency-check'
}
if (-not [string]::IsNullOrWhiteSpace($token)) {
    $headers['Authorization'] = "Bearer $token"
} else {
    Write-Host 'No ECOSYSTEM_PAT or GITHUB_TOKEN present: private repositories will read as not found.' -ForegroundColor Yellow
}

$problems = [System.Collections.Generic.List[string]]::new()

foreach ($project in $lock.projects) {
    if ($RepositoryFilter -and $project.id -ne $RepositoryFilter) {
        continue
    }

    if ($project.repository -notmatch '^[A-Za-z0-9._-]+/[A-Za-z0-9._-]+$') {
        $problems.Add("$($project.id): repository field '$($project.repository)' is not owner/name")
        continue
    }

    $uri = "https://api.github.com/repos/$($project.repository)/git/commits/$($project.revision)"
    try {
        $commit = Invoke-RestMethod -Uri $uri -Headers $headers -Method Get -ErrorAction Stop
        if ($commit.sha -ne $project.revision) {
            $problems.Add("$($project.id): API returned '$($commit.sha)' for pin '$($project.revision)'")
            continue
        }
        Write-Host ("{0,-19} OK       {1} @ {2}" -f $project.id, $project.repository, $project.revision.Substring(0, 12)) -ForegroundColor Green
    } catch {
        $status = 0
        if ($_.Exception.Response) {
            $status = [int]$_.Exception.Response.StatusCode
        }
        switch ($status) {
            404 {
                $problems.Add("$($project.id): commit $($project.revision) not found in $($project.repository) (private without a token, rewritten, or never pushed)")
            }
            403 {
                $problems.Add("$($project.id): rate limited or forbidden querying $($project.repository)")
            }
            0 {
                $problems.Add("$($project.id): could not query $($project.repository): $($_.Exception.Message)")
            }
            default {
                $problems.Add("$($project.id): HTTP $status querying $($project.repository)")
            }
        }
    }
}

if ($problems.Count -gt 0) {
    Write-Host "Pinned-revision check failed ($($problems.Count) issue(s)):" -ForegroundColor Red
    foreach ($problem in $problems) {
        Write-Host " - $problem" -ForegroundColor Red
    }
    exit 1
}

Write-Host 'Every pinned revision exists in its pinned repository.' -ForegroundColor Green