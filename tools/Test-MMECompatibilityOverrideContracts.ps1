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

# DD absent must never enter the full bridge, including non-milking callers.
$ddHelperStart = $source.IndexOf('Bool Function MMEExtDDCheck(')
if ($ddHelperStart -lt 0) { throw "Missing optional-DD guard" }
$beforeDDHelper = $source.Substring(0, $ddHelperStart)
$ddHelper = $source.Substring($ddHelperStart)
if ($beforeDDHelper -match 'DDi\.\w+\(') { throw "A caller bypasses the optional-DD guard" }
if ($ddHelper -notmatch 'target == None' -or
    $ddHelper -notmatch 'Devious Devices - Assets.esm' -or
    $ddHelper -notmatch 'Devious Devices - Integration.esm' -or
    $ddHelper -notmatch 'Quest.GetQuest\("zadQuest"\)' -or
    $ddHelper -notmatch 'available && DDi != None') { throw "DD prerequisites are incomplete" }
$earlyReturn = $ddHelper.IndexOf('If currentState != 1')
$firstBridgeCall = $ddHelper.IndexOf('Return DDi.')
if ($earlyReturn -lt 0 -or $earlyReturn -gt $firstBridgeCall) { throw "DD bridge dispatch precedes the absent-dependency return" }
$requests = [regex]::Matches($beforeDDHelper, 'MMEExtDDCheck\(akActor, "([^"\r\n]+)"\)')
if ($requests.Count -ne 14) { throw "Expected all 14 original DD call sites to be guarded" }
foreach ($request in $requests) {
    $method = $request.Groups[1].Value
    if (!$ddHelper.Contains('Return DDi.' + $method + '(target)')) { throw "Missing original DD dispatch: $method" }
}
if ($ddHelper -match 'Debug\.(Trace|Notification|MessageBox)\(' -or
    $ddHelper -notmatch 'currentState != MMEExtDDLastState') { throw "DD diagnostics must use gated/deduplicated logging" }
Write-Host "PASS: all DD callers use prerequisite guards and original bridge methods; absent DD returns before dispatch"
