[CmdletBinding()]
param(
    # Exit with code 1 when any project has moved off its pin. Off by default:
    # drift is a decision to make, not automatically a defect (see pin_policy).
    [switch]$FailOnDrift
)

# Reporting tool, not a gate: git legitimately writes warnings (for example an
# unreadable .pytest_cache) to stderr, and 'Stop' would turn those into errors.
$ErrorActionPreference = 'Continue'
$root = Split-Path -Parent $PSScriptRoot
$lock = Get-Content -Raw -Encoding utf8 -LiteralPath (Join-Path $root 'ecosystem.lock.json') | ConvertFrom-Json

$matched = 0
$drifting = 0
$rows = [System.Collections.Generic.List[object]]::new()

foreach ($project in $lock.projects) {
    $projectPath = Join-Path $root $project.path
    $pin = $project.revision

    if (-not (Test-Path -LiteralPath (Join-Path $projectPath '.git'))) {
        $rows.Add([pscustomobject]@{
            Project = $project.id
            Pin     = $pin.Substring(0, 12)
            Head    = '-'
            State   = 'NOT-CLONED'
            Dirty   = '-'
            Receipt = $(if ($null -eq $project.verification.receipt) { 'none' } else { 'set' })
        })
        continue
    }

    $head = (& git -C $projectPath rev-parse HEAD 2>$null).Trim()
    if ($LASTEXITCODE -ne 0) {
        $state = 'GIT-ERROR'
    } elseif ($head -eq $pin) {
        $state = 'MATCHED'
        $matched++
    } else {
        & git -C $projectPath cat-file -t $pin 1>$null 2>$null
        if ($LASTEXITCODE -ne 0) {
            $state = 'PIN-ABSENT'
        } else {
            $counts = (& git -C $projectPath rev-list --left-right --count "$pin...$head" 2>$null)
            $sides = ($counts -split '\s+')
            $behind = [int]$sides[0]
            $ahead = [int]$sides[1]
            if ($behind -eq 0) {
                $state = "AHEAD +$ahead"
                if ($project.pin_policy -eq 'frozen') {
                    $state = "$state (frozen)"
                }
            } else {
                $state = "DIVERGED +$ahead/-$behind"
            }
        }
        $drifting++
    }

    $dirtyCount = @(& git -C $projectPath status --porcelain 2>$null).Count
    $rows.Add([pscustomobject]@{
        Project = $project.id
        Pin     = $pin.Substring(0, 12)
        Head    = $head.Substring(0, [Math]::Min(12, $head.Length))
        State   = $state
        Dirty   = $dirtyCount
        Receipt = $(if ($null -eq $project.verification.receipt) { 'none' } else { 'set' })
    })
}

$rows | Format-Table -AutoSize | Out-String -Width 160 | Write-Host

$withoutReceipt = @($lock.projects | Where-Object { $null -eq $_.verification.receipt })
Write-Host "Pins matched: $matched | off-pin: $drifting | projects with no CI receipt: $($withoutReceipt.Count)/$($lock.projects.Count)"

foreach ($project in $lock.projects) {
    if ($project.pin_policy -eq 'frozen') {
        Write-Host "$($project.id) pin is frozen: $($project.pin_note)" -ForegroundColor DarkYellow
    } elseif ($project.pin_note) {
        Write-Host "$($project.id) pin note: $($project.pin_note)" -ForegroundColor DarkYellow
    }
}

if ($withoutReceipt.Count -gt 0) {
    Write-Host 'No receipt above means no CI run certifies that exact revision. Local builds are not receipts.' -ForegroundColor Yellow
}

if ($FailOnDrift -and $drifting -gt 0) {
    exit 1
}
exit 0