$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$armor = Get-Content -LiteralPath (Join-Path $projectRoot "Source\Scripts\MMEArmorScript.psc") -Raw
$mcm = Get-Content -LiteralPath (Join-Path $projectRoot "Source\Scripts\MMEAlertsMCM.psc") -Raw

function Assert-Contract([bool]$condition, [string]$message) {
    if (!$condition) { throw "FAIL: $message" }
    Write-Host "PASS: $message" -ForegroundColor Green
}

Assert-Contract ($mcm -match 'Int Function GetVersion\(\)\s+Return 142') "MCM version includes category controls"
Assert-Contract ($mcm -match 'armorStripCategoriesMigration142' -and $mcm -match '"enableArmorStripHeavy", 1' -and $mcm -match '"enableArmorStripLight", 1' -and $mcm -match '"enableArmorStripClothing", 1') "all three category toggles migrate enabled"
Assert-Contract ($mcm -match 'armorStripHeavyPercent", 70\.0' -and $mcm -match 'armorStripLightPercent", 85\.0' -and $mcm -match 'armorStripClothingPercent", 100\.0') "fresh thresholds default to heavy 70, light 85, clothing 100"
Assert-Contract ($mcm -match 'Enable Heavy Armor Stripping' -and $mcm -match 'Enable Light Armor Stripping' -and $mcm -match 'Enable Clothing Stripping') "Armor MCM exposes all category toggles"
Assert-Contract ($mcm -match 'heavyStripFlags = OPTION_FLAG_DISABLED' -and $mcm -match 'lightStripFlags = OPTION_FLAG_DISABLED' -and $mcm -match 'clothingStripFlags = OPTION_FLAG_DISABLED') "disabled categories visually disable their sliders"
Assert-Contract ($armor -match 'Int Function GetArmorStripCategory' -and $armor -match '0x6BBD2' -and $armor -match '0x6BBD3') "runtime classifies heavy, light, and clothing with Skyrim keywords"
Assert-Contract ($armor -match 'If !IsArmorStripCategoryEnabled\(armorCategory\)[\s\S]*category toggle disabled[\s\S]*Return False') "category toggle blocks before stripping"
Assert-Contract ($armor -match 'IsStripAllArmorEnabled\(\)[\s\S]*GetMMEArmorProtectionReason' -and $armor -match 'IsMilkingBlocked_Suit' -and $armor -match 'IsStripSafeByFramework') "existing override, DD, and SexLab protection flow remains present"
Assert-Contract ($armor -match 'ReportArmorStrip\(diagnostic, sourceLabel \+ " type=" \+ armorKind') "master-gated diagnostics report category decisions"

