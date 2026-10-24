$ErrorActionPreference = "Stop"
$projectRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$mcm = Get-Content -LiteralPath (Join-Path $projectRoot "Source\Scripts\MMEAlertsMCM.psc") -Raw
$body = Get-Content -LiteralPath (Join-Path $projectRoot "Source\Scripts\MMEBodyEffects.psc") -Raw
$controller = Get-Content -LiteralPath (Join-Path $projectRoot "Source\Scripts\MMEAlertsController.psc") -Raw
$build = Get-Content -LiteralPath (Join-Path $projectRoot "build-package.ps1") -Raw
$xedit = Get-Content -LiteralPath (Join-Path $projectRoot "tools\AddMMEBodyEffects.pas") -Raw

function Assert-Contract([bool]$condition, [string]$message) {
    if (!$condition) { throw "Body effects contract failed: $message" }
}

Assert-Contract ($mcm -match 'Pages = new String\[12\]' -and $mcm -match 'Pages\[4\] = "Body"') "Body MCM page is registered"
Assert-Contract ($mcm -match 'enableCustomMilkSpeedDebuff", 0' -and $mcm -match 'enableCustomMilkWeight", 0') "replacement features default off"
Assert-Contract ($mcm -match 'milkSpeedMediumThreshold", 50\.0' -and $mcm -match 'milkSpeedHighThreshold", 100\.0') "threshold defaults are preserved"
Assert-Contract ($mcm -match 'milkSpeedMediumPenalty", 3\.0' -and $mcm -match 'milkSpeedHighPenalty", 10\.0') "penalty defaults are preserved"
Assert-Contract ($mcm -match 'disable MME''s original unmilked speed debuff' -and $mcm -match 'prevent stacking') "MCM warns about original MME overlap"
Assert-Contract (($mcm | Select-String -Pattern 'AddHeaderOption\("Milk Maid Weight"\)' -AllMatches).Matches.Count -eq 0) "old Misc appearance-weight header was removed"
Assert-Contract ($mcm -match 'AddHeaderOption\("Milk Maid Appearance"\)' -and $mcm -match 'maidWeightPerLevel') "existing appearance controls moved without renaming their key"
Assert-Contract ($body -match 'If fullness >= highThreshold' -and $body -match 'ElseIf fullness >= mediumThreshold') "high and medium tiers are mutually exclusive"
Assert-Contract ($body -match '1\.0 \+ \(maidLevel as Float / 100\.0\)') "level 100 reaches a 2x multiplier"
Assert-Contract ($body -match 'ModActorValue\("SpeedMult"' -and $body -match 'ModActorValue\("CarryWeight"') "speed and carry penalties have independently owned modifiers"
Assert-Contract ($body -match '0x0008C1' -and $body -match '0x0008C3') "speed and carry penalties have separate display abilities"
Assert-Contract ($body -match 'RefreshDisplayEffects\(player, speedPenalty, carryPenalty\)' -and $body -match 'SetNthEffectMagnitude\(0, magnitude\)') "Active Effects use the final owned penalty magnitudes"
Assert-Contract ($body -match 'previousMagnitude < \(magnitude - 0\.001\)' -and $body -match 'display updated') "display refresh and footprints occur only when state changes"
Assert-Contract ($mcm -match 'AddToggleOption\("Milk Has Weight"' -and $mcm -notmatch 'AddToggleOption\("Milk Has Custom Weight"') "MCM uses the approved label without renaming its saved key"
Assert-Contract ($xedit -match 'MilkWeightEffectLocalID = \$0008C2' -and $xedit -match 'MilkWeightAbilityLocalID = \$0008C3') "xEdit reserves fixed collision-checked weight display records"
Assert-Contract ($xedit -match "SetElementEditValues\(bodyAbility, 'DESC', 'Movement speed reduced by <mag>%\.'\)" -and $xedit -match "SetElementEditValues\(milkWeightAbility, 'DESC', 'Carried milk reduces carry capacity by <mag> points\.'\)") "both displayed ability descriptions expose their final magnitude token"
Assert-Contract ($controller -match 'NextBodyEffectsUpdate' -and $controller -match 'MMEBodyEffects\.Reconcile') "body reconciliation uses the shared scheduler"
Assert-Contract ($build -match '\$scriptNames \+= "MMEBodyEffects"' -and $build -match 'Test-BodyEffectsContracts') "release build compiles and tests the feature"

Write-Host "Body effects contracts passed." -ForegroundColor Green
