$ErrorActionPreference = "Stop"
$projectRoot = Split-Path -Parent $PSScriptRoot
$overridePath = Join-Path $projectRoot "Source\MMECompatibilityOverrides\MilkQUEST.psc"
$source = (Get-Content -LiteralPath $overridePath -Raw).Replace("`r`n", "`n")

if ($source -match 'MMEMilkingDiagnostics') {
    throw "The MME compatibility override still contains invasive diagnostic hooks"
}
if ($source -match 'int i = 0\n\s*int count = 0\n\s*int t = MILKmaid\.Find\(none,1\)') {
    throw "An NPC Milk Maid assignment loop still begins at slot 0"
}
$fixedLoops = [regex]::Matches($source, 'int i = 1\n\s*int count = 0\n\s*int t = MILKmaid\.Find\(none,1\)[\s\S]*?While i < MilkMaid\.Length\n\s*If MilkMaid\[i\] != None[\s\S]*?i \+= 1\n\s*EndWhile')
if ($fixedLoops.Count -ne 2) {
    throw "AssignSlot and AssignSlotMaid must both scan slots 1..Length-1 safely"
}
if ($source -notmatch 'SendModEvent\( "MME_MilkCycleComplete" \)') {
    throw "The compatibility override lost the cycle-complete integration hook"
}
if ($source -match 'GetExpressionByName\([^\r\n]+\)\.ApplyTo') {
    throw "The MME compatibility override still chains ApplyTo onto a possibly missing SexLab expression"
}
if ($source -notmatch 'Function MMEExtApplyExpressionSafe' -or
    ([regex]::Matches($source, 'MMEExtApplyExpressionSafe\(akActor,').Count -ne 8)) {
    throw "Both MME milking loops must route all eight facial-expression calls through the null-safe helper"
}
if ($source -notmatch 'MMELog\.MasterDiagnostic' -or $source -notmatch 'MMEExtMissingExpressionReported') {
    throw "Missing SexLab expressions must leave one master-debug breadcrumb without per-tick spam"
}
if ($source -match 'Debug\.Messagebox\("Gag prevents feeding"\)') {
    throw "Closed gags must not display the original modal feeding popup"
}
if ($source -notmatch 'feeding blocked by closed ZaZ gag' -or
    $source -notmatch 'feeding blocked by closed Devious Devices gag') {
    throw "Closed-gag feeding blocks must leave master-debug breadcrumbs for ZaZ and Devious Devices"
}
if (Test-Path -LiteralPath (Join-Path $projectRoot "Source\MMECompatibilityOverrides\MME_StartMilking.psc")) {
    throw "The diagnostic MME_StartMilking override must not ship"
}

Write-Host "PASS: minimal MME override fixes NPC assignment loops, preserves the cycle hook, safely handles missing SexLab expressions, and suppresses modal gag spam"
