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
if (Test-Path -LiteralPath (Join-Path $projectRoot "Source\MMECompatibilityOverrides\MME_StartMilking.psc")) {
    throw "The diagnostic MME_StartMilking override must not ship"
}

Write-Host "PASS: minimal MME override fixes both NPC assignment loops and retains only the required cycle hook"
