[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$BaaPath,

    [Parameter(Mandatory = $true)]
    [string]$QalamBuildDir,

    [string]$BaaLspBuildDir = "",

    # Nazm is Baa's production assembler, so every hosted build needs it.
    [Parameter(Mandatory = $true)]
    [string]$NazmPath,

    [string]$NazmBuildDir = "",
    [string[]]$RuntimeBin = @()
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$oldPath = $env:PATH
$oldBaa = $env:BAA
$oldBaaStdlib = $env:BAA_STDLIB
$oldBaaNazm = $env:BAA_NAZM
$oldNazm = $env:NAZM
$oldQtPlatform = $env:QT_QPA_PLATFORM

function Invoke-Step([string]$Label, [scriptblock]$Action) {
    Write-Host "==> $Label" -ForegroundColor Cyan
    $global:LASTEXITCODE = 0
    & $Action
    if ($LASTEXITCODE -ne 0) {
        throw "$Label failed with exit code $LASTEXITCODE."
    }
}

function Find-BaaStdlib([string]$CompilerPath) {
    $probe = (Get-Item -LiteralPath (Split-Path -Parent $CompilerPath))
    while ($probe) {
        $candidate = Join-Path $probe.FullName 'stdlib'
        if (Test-Path -LiteralPath (Join-Path $candidate 'baalib.baahd')) {
            return $candidate
        }
        $probe = $probe.Parent
    }
    throw 'Unable to locate Baa stdlib beside an ancestor of the compiler.'
}

try {
    $resolvedBaa = (Get-Command $BaaPath -ErrorAction Stop).Source
    $resolvedQalamBuild = (Resolve-Path -LiteralPath $QalamBuildDir).Path
    $resolvedNazm = (Get-Command $NazmPath -ErrorAction Stop).Source
    $resolvedBaaLspBuild = if ($BaaLspBuildDir) {
        (Resolve-Path -LiteralPath $BaaLspBuildDir).Path
    } else { "" }
    $runtimeParts = @($RuntimeBin | ForEach-Object { (Resolve-Path -LiteralPath $_).Path })
    $runtimeParts += Split-Path -Parent $resolvedBaa
    $env:PATH = (($runtimeParts + $oldPath) -join [IO.Path]::PathSeparator)
    $env:BAA = $resolvedBaa
    $env:BAA_STDLIB = Find-BaaStdlib $resolvedBaa
    $env:BAA_NAZM = $resolvedNazm
    $env:NAZM = $resolvedNazm
    $env:QT_QPA_PLATFORM = 'offscreen'

    Invoke-Step 'Eco contract consistency' {
        & (Join-Path $PSScriptRoot 'check-ecosystem.ps1')
    }

    Invoke-Step 'Baa quick QA' {
        Push-Location (Join-Path $root 'Baa')
        try { python (Join-Path 'scripts' 'qa_run.py') --mode quick } finally { Pop-Location }
    }

    Invoke-Step 'Takween hosted smoke' {
        Push-Location (Join-Path $root 'Takween')
        try { & ./scripts/test_takween.ps1 -BaaPath $resolvedBaa -NazmPath $resolvedNazm } finally { Pop-Location }
    }

    if ($IsWindows -or $env:OS -eq 'Windows_NT') {
        $qalamTests = @(Get-ChildItem -LiteralPath (Join-Path $resolvedQalamBuild 'tests') -File -Filter 'test_*.exe')
        if ($qalamTests.Count -eq 0) {
            throw "No Qalam test executables found under $resolvedQalamBuild."
        }
        foreach ($test in $qalamTests) {
            Invoke-Step ("Qalam " + $test.BaseName) { & $test.FullName -txt }
        }
    } else {
        Invoke-Step 'Qalam CTest suite' {
            ctest --test-dir $resolvedQalamBuild --output-on-failure
        }
    }

    if ($resolvedBaaLspBuild) {
        Invoke-Step 'Baa-LSP CTest suite' {
            ctest --test-dir $resolvedBaaLspBuild --output-on-failure
        }
        $serverName = if ($IsWindows -or $env:OS -eq 'Windows_NT') {
            'baa-lsp.exe'
        } else { 'baa-lsp' }
        $server = Get-ChildItem -LiteralPath $resolvedBaaLspBuild -Recurse -File |
            Where-Object { $_.Name -eq $serverName } |
            Select-Object -First 1
        if (-not $server) {
            throw "No Baa-LSP executable found under $resolvedBaaLspBuild."
        }
        Invoke-Step 'Baa-LSP real Baa document-symbol protocol' {
            python (Join-Path $root 'Baa-LSP/tests/TestRealBaaProtocol.py') `
                $server.FullName $resolvedBaa
        }
    }

    if ($NazmBuildDir) {
        $resolvedNazmBuild = (Resolve-Path -LiteralPath $NazmBuildDir).Path
        Invoke-Step 'Nazm CTest suite' {
            ctest --test-dir $resolvedNazmBuild --output-on-failure
        }
    }

    Write-Host 'Hosted ecosystem smoke passed.' -ForegroundColor Green
} finally {
    $env:PATH = $oldPath
    $env:BAA = $oldBaa
    $env:BAA_STDLIB = $oldBaaStdlib
    $env:BAA_NAZM = $oldBaaNazm
    $env:NAZM = $oldNazm
    $env:QT_QPA_PLATFORM = $oldQtPlatform
}
