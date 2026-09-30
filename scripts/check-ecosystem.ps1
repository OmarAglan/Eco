[CmdletBinding()]
param(
    # Validate only what the umbrella owns (lock structure, README, roadmap).
    # Assertions that target a member repository are reported as skipped, never
    # as passed, so a checkout-less CI job can never claim a false green.
    [switch]$LockOnly
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$failures = [System.Collections.Generic.List[string]]::new()
$skipped = [System.Collections.Generic.List[string]]::new()

$projectScopes = @(
    'Baa',
    'Nazm',
    'Takween',
    'Qalam-IDE',
    'Baa-LSP',
    'ArbSh',
    'Baa-Developer-Kit',
    'Pyramid-Engine',
    'PyramidOS'
)

function Test-ProjectScope([string]$RelativePath) {
    $firstSegment = ($RelativePath -split '[\\/]')[0]
    return ($projectScopes -contains $firstSegment)
}

function Add-Failure([string]$Message) {
    $failures.Add($Message)
}

function Require-Path([string]$RelativePath) {
    if ($LockOnly -and (Test-ProjectScope $RelativePath)) {
        $skipped.Add("path: $RelativePath")
        return
    }

    $path = Join-Path $root $RelativePath
    if (-not (Test-Path -LiteralPath $path)) {
        Add-Failure "Missing required path: $RelativePath"
    }
}

function Require-Match([string]$RelativePath, [string]$Pattern, [string]$Description) {
    if ($LockOnly -and (Test-ProjectScope $RelativePath)) {
        $skipped.Add("match: $Description")
        return
    }

    $path = Join-Path $root $RelativePath
    Require-AbsoluteMatch $path $Pattern $Description
}

function Require-AbsoluteMatch([string]$Path, [string]$Pattern, [string]$Description) {
    if (-not (Test-Path -LiteralPath $Path)) {
        Add-Failure "Missing file for ${Description}: $Path"
        return
    }

    $content = Get-Content -Raw -Encoding utf8 -LiteralPath $Path
    if ($content -notmatch $Pattern) {
        Add-Failure "${Description} not found in $Path"
    }
}

$lockPath = Join-Path $root 'ecosystem.lock.json'
Require-Path 'README.md'
Require-Path 'ECOSYSTEM_ROADMAP.md'
Require-Path 'ecosystem.lock.json'

if (Test-Path -LiteralPath $lockPath) {
    try {
        $lock = Get-Content -Raw -Encoding utf8 -LiteralPath $lockPath | ConvertFrom-Json
    } catch {
        Add-Failure "ecosystem.lock.json is not valid JSON: $($_.Exception.Message)"
    }

    if ($null -ne $lock) {
        if ($lock.schema_version -ne 'eco-lock-v1') {
            Add-Failure "Unsupported ecosystem lock schema: $($lock.schema_version)"
        }

        $expectedIds = @(
            'baa',
            'nazm',
            'takween',
            'qalam',
            'baa-lsp',
            'arbsh',
            'baa-developer-kit',
            'pyramid-engine',
            'pyramidos'
        )
        $actualIds = @($lock.projects | ForEach-Object { $_.id })
        foreach ($id in $expectedIds) {
            if ($id -notin $actualIds) {
                Add-Failure "ecosystem.lock.json does not contain project '$id'"
            }
        }
        if ($actualIds.Count -ne $expectedIds.Count) {
            Add-Failure "ecosystem.lock.json project count mismatch: expected=$($expectedIds.Count), actual=$($actualIds.Count)"
        }
        $duplicateIds = @($actualIds | Group-Object | Where-Object Count -gt 1)
        foreach ($duplicate in $duplicateIds) {
            Add-Failure "ecosystem.lock.json contains duplicate project '$($duplicate.Name)'"
        }

        foreach ($project in $lock.projects) {
            if ($project.repository -notmatch '^[A-Za-z0-9._-]+/[A-Za-z0-9._-]+$') {
                Add-Failure "Project '$($project.id)' needs a 'repository' of the form owner/name"
            }

            $pendingGates = @()
            if ($null -ne $project.pending_gates) {
                $pendingGates = @($project.pending_gates | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
            }
            if ($pendingGates.Count -eq 0) {
                Add-Failure "Project '$($project.id)' declares no pending_gates; an unverified component may not claim to be finished"
            }

            # A receipt may only certify the revision the lock actually pins.
            # This is what stops an old green run from being reused as proof for
            # a revision that moved.
            $receipt = $project.verification.receipt
            if ($null -ne $receipt) {
                if ($receipt.run_url -notmatch '^https://github\.com/[A-Za-z0-9._-]+/[A-Za-z0-9._-]+/actions/runs/[0-9]+$') {
                    Add-Failure "Project '$($project.id)' receipt has a run_url that is not a GitHub Actions run URL"
                }
                if ($receipt.verified_revision -ne $project.revision) {
                    Add-Failure "Project '$($project.id)' receipt certifies '$($receipt.verified_revision)' but the lock pins '$($project.revision)'; the receipt does not cover this pin"
                }
                if ($receipt.verified_at -notmatch '^[0-9]{4}-[0-9]{2}-[0-9]{2}$') {
                    Add-Failure "Project '$($project.id)' receipt needs an ISO 'verified_at' date"
                }
            }

            Require-Path $project.path
            Require-Path (Join-Path $project.path $project.version_source)

            if ($project.revision -notmatch '^[0-9a-f]{40}$') {
                Add-Failure "Project '$($project.id)' does not have an exact 40-character revision pin"
                continue
            }

            $projectPath = Join-Path $root $project.path
            if ($LockOnly) {
                continue
            }

            if (Test-Path -LiteralPath (Join-Path $projectPath '.git')) {
                $actualRevision = (& git -C $projectPath rev-parse HEAD 2>$null).Trim()
                if ($LASTEXITCODE -ne 0) {
                    Add-Failure "Could not read Git revision for project '$($project.id)'"
                } elseif ($actualRevision -ne $project.revision) {
                    $shape = "the pinned revision is not reachable from this clone"
                    & git -C $projectPath cat-file -t $project.revision 1>$null 2>$null
                    if ($LASTEXITCODE -eq 0) {
                        $counts = & git -C $projectPath rev-list --left-right --count "$($project.revision)...$actualRevision" 2>$null
                        if ($LASTEXITCODE -eq 0 -and $counts) {
                            $sides = ($counts -split '\s+')
                            $behind = $sides[0]
                            $ahead = $sides[1]
                            $shape = "workspace is $ahead commit(s) ahead of the pin and $behind behind"
                            if ($behind -eq '0') {
                                $shape = "$shape (straight-line advance, not a divergence)"
                            }
                        }
                    }

                    $note = ''
                    if ($project.pin_note) {
                        $note = " | pin is deliberate: $($project.pin_note)"
                    }

                    Add-Failure "Project '$($project.id)' revision drift: lock=$($project.revision), workspace=$actualRevision - $shape$note"
                }
            }
        }

        # Milestone status is data in the lock, not a sentence in prose. The
        # roadmap is verified against it structurally: a milestone may only be
        # closed when its own section has no unchecked work items left.
        $milestones = @()
        if ($null -ne $lock.milestones) {
            $milestones = @($lock.milestones | Where-Object { $null -ne $_ })
        }
        if ($milestones.Count -eq 0) {
            Add-Failure 'ecosystem.lock.json declares no milestones'
        }

        $validMilestoneStates = @('closed', 'in-progress', 'not-started')
        $roadmapText = ''
        $roadmapFile = Join-Path $root 'ECOSYSTEM_ROADMAP.md'
        if (Test-Path -LiteralPath $roadmapFile) {
            $roadmapText = Get-Content -Raw -Encoding utf8 -LiteralPath $roadmapFile
        } else {
            Add-Failure 'Missing ECOSYSTEM_ROADMAP.md needed to verify milestone states'
        }

        $declaredMilestoneIds = @($milestones | ForEach-Object { $_.id })
        foreach ($heading in [regex]::Matches($roadmapText, '(?m)^## (E[0-9]+) .*$')) {
            if ($heading.Groups[1].Value -notin $declaredMilestoneIds) {
                Add-Failure "ECOSYSTEM_ROADMAP.md declares milestone $($heading.Groups[1].Value) which is absent from ecosystem.lock.json"
            }
        }

        foreach ($milestone in $milestones) {
            if ($milestone.state -notin $validMilestoneStates) {
                Add-Failure "Milestone '$($milestone.id)' has unsupported state '$($milestone.state)'"
                continue
            }

            $sectionPattern = "(?ms)^## $([regex]::Escape($milestone.id)) .+?(?=^## |\z)"
            $section = [regex]::Match($roadmapText, $sectionPattern)
            if (-not $section.Success) {
                Add-Failure "Milestone '$($milestone.id)' has no '## $($milestone.id)' section in ECOSYSTEM_ROADMAP.md"
                continue
            }

            if ($milestone.title -and ($section.Value -notmatch [regex]::Escape($milestone.title))) {
                Add-Failure "Milestone '$($milestone.id)' is titled '$($milestone.title)' in the lock but ECOSYSTEM_ROADMAP.md says otherwise"
            }

            $openItems = [regex]::Matches($section.Value, '(?m)^\s*- \[ \]').Count
            $doneItems = [regex]::Matches($section.Value, '(?m)^\s*- \[x\]').Count

            if ($milestone.state -eq 'closed' -and $openItems -gt 0) {
                Add-Failure "Milestone '$($milestone.id)' is declared closed but ECOSYSTEM_ROADMAP.md still lists $openItems unchecked item(s) in it"
            }
            if ($milestone.state -eq 'not-started' -and $doneItems -gt 0) {
                Add-Failure "Milestone '$($milestone.id)' is declared not-started but ECOSYSTEM_ROADMAP.md lists $doneItems completed item(s) in it"
            }
        }
    }
}

Require-Match 'Baa/CMakeLists.txt' 'project\(baa VERSION 0\.6\.0' 'Baa 0.6.0 version'
Require-Match 'Nazm/CMakeLists.txt' 'VERSION 0\.4\.0' 'Nazm 0.4.0 version'
Require-Match 'Qalam-IDE/CMakeLists.txt' 'project\(QalamIDE VERSION 3\.6\.0' 'Qalam 3.6.0 version'
Require-Match 'Baa-LSP/CMakeLists.txt' 'project\(BaaLSP VERSION 0\.1\.0' 'Baa-LSP 0.1.0 version'
Require-Match 'Takween/scripts/build_takween.ps1' '\$Version = "0\.1\.0"' 'Takween 0.1.0 version'
Require-Match 'ArbSh/README.md' 'Current Version:\*\* 0\.8\.1-alpha' 'ArbSh 0.8.1-alpha version'
Require-Match 'Baa-Developer-Kit/scripts/Build-DeveloperKitInstaller.ps1' "ReleaseVersion = '0\.5\.0'" 'Baa Developer Kit 0.5.0 version'
Require-Match 'Pyramid-Engine/CMakeLists.txt' 'project\(Pyramid VERSION 0\.6\.0' 'Pyramid Engine 0.6.0 version'
Require-Match 'PyramidOS/docs/ROADMAP_L3_TACTICAL.md' 'Current Kernel:\*\* v0\.8\.1' 'PyramidOS 0.8.1 baseline'

$requiredDocs = @(
    'Baa/docs/ECOSYSTEM_BOUNDARIES.md',
    'Baa/docs/COMPATIBILITY_MATRIX.md',
    'Baa/docs/TOOLING_CONTRACTS.md',
    'Baa/docs/DIAGNOSTICS_JSON_SCHEMA.md',
    'Baa/docs/NAZM_SHADOW_INTEGRATION.md',
    'Nazm/Docs/BAA_INTEGRATION.md',
    'Takween/ROADMAP.md',
    'Qalam-IDE/documents/INTERNALS.md',
    'Baa-LSP/docs/ARCHITECTURE_AR.md',
    'ArbSh/docs/ARBSH_HOST_V1.md',
    'Baa-Developer-Kit/docs/WINDOWS_INSTALLER_CONTRACT.md',
    'Pyramid-Engine/docs/ROADMAP.md',
    'PyramidOS/docs/BAA_TAKWEEN_OS_INTEGRATION_PLAN.md'
)
foreach ($doc in $requiredDocs) {
    Require-Path $doc
}

if (-not $LockOnly) {
    $takweenFormat = Get-ChildItem -LiteralPath (Join-Path $root 'Takween') -Recurse -File -Filter 'FORMAT.md' |
        Select-Object -First 1
    if (-not $takweenFormat) {
        Add-Failure 'Missing Takween FORMAT.md'
    }

    $takweenManifest = Get-ChildItem -LiteralPath (Join-Path $root 'Takween') -Recurse -File -Filter 'MANIFEST_V1.md' |
        Select-Object -First 1
    if (-not $takweenManifest) {
        Add-Failure 'Missing Takween MANIFEST_V1.md'
    }

    $takweenPackages = Get-ChildItem -LiteralPath (Join-Path $root 'Takween') -Recurse -File -Filter 'PACKAGES.md' |
        Select-Object -First 1
    if (-not $takweenPackages) {
        Add-Failure 'Missing Takween PACKAGES.md'
    }
} else {
    $skipped.Add('Takween FORMAT.md / MANIFEST_V1.md / PACKAGES.md discovery')
}

Require-Match 'Baa/docs/ECOSYSTEM_BOUNDARIES.md' '\| Nazm \|' 'Nazm ecosystem ownership row'
Require-Match 'Baa/docs/ECOSYSTEM_BOUNDARIES.md' '\| ArbSh \|' 'ArbSh ecosystem ownership row'
Require-Match 'Baa/docs/ECOSYSTEM_BOUNDARIES.md' '\| Pyramid-Engine \|' 'Pyramid Engine ecosystem ownership row'
Require-Match 'Baa/docs/ECOSYSTEM_BOUNDARIES.md' '\| Baa-Developer-Kit \|' 'Baa Developer Kit ecosystem ownership row'
Require-Match 'Baa/docs/COMPATIBILITY_MATRIX.md' 'baa-nazm-boundary-v0' 'Baa/Nazm compatibility contract'
Require-Match 'Baa/docs/NAZM_SHADOW_INTEGRATION.md' '100 sources per target' 'Baa assembly inventory receipt'
Require-Match 'Nazm/Docs/BAA_INTEGRATION.md' 'Baa `0\.6\.0`' 'current Baa baseline in Nazm integration'
Require-Match 'Takween/ROADMAP.md' 'diagnostics-json-v1' 'Takween structured diagnostics migration'
Require-Match 'Baa/docs/TOOLING_CONTRACTS.md' 'symbols-json-v1' 'Baa document-symbol contract'
Require-Match 'Baa/docs/TOOLING_CONTRACTS.md' 'completion-data-json-v1' 'Baa completion-data contract'
Require-Match 'Baa/docs/TOOLING_CONTRACTS.md' 'semantic-query-json-v1' 'Baa cursor semantic-query contract'
Require-Match 'Baa/docs/TOOLING_CONTRACTS.md' 'inlay-hints-json-v1' 'Baa compiler-owned inlay-hint contract'
Require-Match 'Baa-LSP/ROADMAP.md' '\[x\] Implement `textDocument/documentSymbol`' 'Baa-LSP document-symbol capability'
Require-Match 'Baa-LSP/ROADMAP.md' '\[x\] Implement Arabic-prefix `textDocument/completion`' 'Baa-LSP completion capability'
Require-Match 'Baa-LSP/ROADMAP.md' '\[x\] Implement compiler-backed hover and signature help' 'Baa-LSP semantic tooltip capabilities'
Require-Match 'Baa-LSP/ROADMAP.md' '\[x\] Compiler-owned Arabic parameter-name hints' 'Baa-LSP inlay-hint capability'
Require-Match 'Baa-LSP/ROADMAP.md' 'Telemetry-free structured server logs through opt-in `baa-lsp-log-v1`' 'Baa-LSP structured log contract'
Require-Match 'Qalam-IDE/documents/BAA_LSP_INTEGRATION_AR.md' 'symbols-json-v1' 'Qalam document-symbol consumption'
Require-Match 'Qalam-IDE/documents/BAA_LSP_INTEGRATION_AR.md' 'completion-data-json-v1' 'Qalam completion-data consumption'
Require-Match 'Qalam-IDE/documents/BAA_LSP_INTEGRATION_AR.md' 'semantic-query-json-v1' 'Qalam cursor semantic-query consumption'
Require-Match 'Qalam-IDE/documents/BAA_LSP_INTEGRATION_AR.md' 'inlay-hints-json-v1' 'Qalam compiler-owned inlay-hint consumption'
Require-Match 'Qalam-IDE/documents/BAA_LSP_INTEGRATION_AR.md' 'baa-lsp-log-v1' 'Qalam structured log consumption'
Require-Match 'Qalam-IDE/tests/CMakeLists.txt' 'CheckQalamNaming\.cmake' 'Qalam-owned source naming guard'
Require-Match 'Qalam-IDE/tests/CMakeLists.txt' '--unset=PATH' 'Qalam deterministic Windows test runtime'
Require-Match 'Qalam-IDE/documents/WORKBENCH_EVOLUTION_AR.md' 'المرحلة أ: فتح المشروع واستعادة الجلسة — مكتملة في [0-9]+\.[0-9]+\.[0-9]+' 'Qalam Workbench Phase A completion receipt'
Require-Match 'Qalam-IDE/documents/WORKBENCH_EVOLUTION_AR.md' 'المرحلة ب: مجموعات المحرر — مكتملة في [0-9]+\.[0-9]+\.[0-9]+' 'Qalam Workbench Phase B completion receipt'
Require-Match 'Qalam-IDE/tests/CMakeLists.txt' 'TestEditorWorkspace\.cpp' 'Qalam shared editor workspace tests'
Require-Match 'Qalam-IDE/tests/CMakeLists.txt' 'TestWelcomePage\.cpp' 'Qalam recent-project welcome tests'
Require-Match 'Baa-LSP/tests/CMakeLists.txt' '--unset=PATH' 'Baa-LSP deterministic Windows test runtime'
if ($takweenPackages) {
    Require-AbsoluteMatch $takweenPackages.FullName 'takween-index-v1' 'Takween local package index contract'
    Require-AbsoluteMatch $takweenPackages.FullName '--locked' 'Takween immutable lock verification contract'
}
Require-Match 'ecosystem.lock.json' 'implemented-cross-platform-verified' 'verified compiler CLI contract state'
Require-Match 'ecosystem.lock.json' 'path-git-local-archive-preview' 'Takween lock preview state'
Require-Match 'ecosystem.lock.json' 'inlay-hints-json-v1-implemented-cross-platform-verified' 'verified inlay-hint contract state'
Require-Match 'ecosystem.lock.json' 'baa-lsp-log-v1-cross-platform-verified' 'verified structured log contract state'
Require-Match 'ecosystem.lock.json' 'production-default-cross-platform-verified' 'verified Nazm production-default contract state'
Require-Match 'ArbSh/docs/ARBSH_HOST_V1.md' 'arbsh-host-v1' 'ArbSh host contract plan'
Require-Match 'ECOSYSTEM_ROADMAP.md' 'eco-arabic-text-corpus-v1' 'shared Arabic interaction corpus plan'
Require-Match 'Pyramid-Engine/docs/ROADMAP.md' 'Baa scripting admission gate' 'Pyramid Engine Baa scripting boundary'
Require-Match 'PyramidOS/docs/BAA_TAKWEEN_OS_INTEGRATION_PLAN.md' 'i386/ELF32' 'Nazm target-strategy gap recorded in PyramidOS plan'

if ($failures.Count -gt 0) {
    Write-Host "Eco consistency check failed ($($failures.Count) issue(s)):" -ForegroundColor Red
    foreach ($failure in $failures) {
        Write-Host " - $failure" -ForegroundColor Red
    }
    if ($skipped.Count -gt 0) {
        Write-Host "$($skipped.Count) member-repository assertion(s) were skipped and are NOT verified." -ForegroundColor Yellow
    }
    exit 1
}

if ($LockOnly) {
    Write-Host 'Eco lock and umbrella-document checks passed (lock-only mode).' -ForegroundColor Green
    Write-Host "$($skipped.Count) member-repository assertion(s) were skipped because those repositories are not checked out here. They are UNVERIFIED, not passed." -ForegroundColor Yellow
    exit 0
}

Write-Host 'Eco consistency check passed.' -ForegroundColor Green
Write-Host 'Validated nine projects, pinned revisions, receipt coverage, milestone evidence, contracts, and integration ownership.'
