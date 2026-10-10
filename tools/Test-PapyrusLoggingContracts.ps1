$ErrorActionPreference = "Stop"
$projectRoot = Split-Path -Parent $PSScriptRoot
$mcm = Get-Content -LiteralPath (Join-Path $projectRoot "Source\Scripts\MMEAlertsMCM.psc") -Raw
$log = Get-Content -LiteralPath (Join-Path $projectRoot "Source\Scripts\MMELog.psc") -Raw
$debug = Get-Content -LiteralPath (Join-Path $projectRoot "Source\Scripts\MMEDebug.psc") -Raw
$dialogue = Get-Content -LiteralPath (Join-Path $projectRoot "Source\Scripts\MMENPCDialog.psc") -Raw
$diagnostics = Get-Content -LiteralPath (Join-Path $projectRoot "Source\Scripts\MMEDiagnostics.psc") -Raw

if ($mcm -notmatch 'AddToggleOption\("Papyrus Logging"' -or $mcm -notmatch 'AddToggleOption\("Verbose Papyrus Logging"') {
    throw "The Troubleshoot MCM does not expose the two consolidated logging levels"
}
foreach ($removedLabel in @('Specific Diagnostic Traces', 'Papyrus Audit Trace', 'Vendor Animation', 'Milk Dialogue Timing')) {
    $legacyCall = 'AddToggleOption("' + $removedLabel + '"'
    if ($mcm -match [regex]::Escape($legacyCall)) { throw "Legacy public logging toggle remains: $removedLabel" }
}
if ($mcm -notmatch 'verbosePapyrusLoggingMigration146' -or $mcm -notmatch 'enableVerbosePapyrusLogging') {
    throw "Verbose logging default or existing-save migration is missing"
}
if ($log -notmatch 'enablePapyrusTrace' -or $log -notmatch 'enableVerbosePapyrusLogging') {
    throw "Verbose diagnostics are not gated by both public logging levels"
}
if ($debug -notmatch 'Bool Function IsVendorAnimationTraceEnabled\(\)[\s\S]*?MMELog\.IsDiagnosticEnabled\(\)' -or $dialogue -notmatch 'Bool Function IsDialogueTimingTraceEnabled\(\) Global[\s\S]*?MMELog\.IsDiagnosticEnabled\(\)') {
    throw "Vendor or milk-dialogue detail did not move to verbose logging"
}
if ($diagnostics -match 'enableDiagnosticPapyrusTrace') {
    throw "Manual audit logging still reads the retired public trace setting"
}
Write-Host "Papyrus logging contracts passed." -ForegroundColor Green
