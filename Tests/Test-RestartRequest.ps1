#Requires -Version 5.1
<#
.SYNOPSIS
    Tests how the launcher reads restart.txt: the countdown and message Kiosk
    Fleet Web writes as JSON, and the old empty or plain-text file.

.DESCRIPTION
    Loads Read-RestartRequest from the launcher without running it, so it
    needs no Edge and no kiosk, and runs on any PowerShell, Windows or not.

.EXAMPLE
    .\Tests\Test-RestartRequest.ps1
#>
[CmdletBinding()]
param(
    [string]$Launcher = (Join-Path $PSScriptRoot '..\PbiLauncher\PbiLauncher.ps1')
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 2.0
$Launcher = (Resolve-Path -LiteralPath $Launcher).ProviderPath
$errors = $null
$ast = [Management.Automation.Language.Parser]::ParseFile($Launcher, [ref]$null, [ref]$errors)
$failed = 0
function Test-Check {
    param([string]$Name, [bool]$Pass, [string]$Detail = '')
    if (-not $Pass) { $script:failed++ }
    $suffix = if ($Detail) { "  ($Detail)" } else { '' }
    Write-Host ("  [{0}] {1}{2}" -f $(if ($Pass) { 'PASS' } else { 'FAIL' }), $Name, $suffix) -ForegroundColor $(if ($Pass) { 'Green' } else { 'Red' })
}
Test-Check 'the launcher parses' ($errors.Count -eq 0) (($errors | ForEach-Object { $_.Message }) -join '; ')
$fn = $ast.FindAll({ param($n) $n -is [Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -eq 'Read-RestartRequest' }, $true) | Select-Object -First 1
Test-Check 'it has Read-RestartRequest' ($null -ne $fn)
if (-not $fn) { exit 1 }
. ([scriptblock]::Create($fn.Extent.Text))
$script:Logged = @()
function Write-Log { param($Message, $Level) $script:Logged += "$Level $Message" }

$dir = Join-Path ([IO.Path]::GetTempPath()) ('restart-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $dir | Out-Null
$file = Join-Path $dir 'restart.txt'
try {
    # file content, seconds, message, by
    $cases = @(
        @('', 10, '', ''),
        @('2026-10-02T10:00:00 by alice (admin) from Kiosk Fleet Web', 10, '', ''),
        @('{"Seconds": 60, "Message": "Back in\na minute", "By": "alice (admin)"}', 60, 'Back in a minute', 'alice (admin)'),
        @('{"Seconds": 0, "Message": "", "By": "bob"}', 0, '', 'bob'),
        @('{"Seconds": 99999}', 3600, '', ''),
        @('{"Seconds": -5}', 0, '', ''),
        @('{"Seconds": "soon"}', 10, '', ''),
        @('{"Message": "only a message"}', 10, 'only a message', ''),
        @('{not json', 10, '', '')
    )
    foreach ($c in $cases) {
        [IO.File]::WriteAllText($file, $c[0])
        $r = Read-RestartRequest $file
        $shown = ($c[0] -replace "`n", '\n')
        Test-Check "'$shown'" (($r.Seconds -eq $c[1]) -and ($r.Message -eq $c[2]) -and ($r.By -eq $c[3])) ("{0} s, '{1}', by '{2}'" -f $r.Seconds, $r.Message, $r.By)
    }
    Test-Check 'a file that is not JSON is logged, not fatal' (@($script:Logged | Where-Object { $_ -like 'WARN restart.txt could not be read*' }).Count -eq 1) ($script:Logged -join ' | ')
    Test-Check 'the file is left for the caller to delete' (Test-Path -LiteralPath $file)
}
finally { Remove-Item -LiteralPath $dir -Recurse -Force -ErrorAction SilentlyContinue }

Write-Host ("{0} failed." -f $failed) -ForegroundColor $(if ($failed) { 'Red' } else { 'Green' })
exit $failed
