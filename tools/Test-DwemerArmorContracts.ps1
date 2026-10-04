$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$dwemer = Get-Content -LiteralPath (Join-Path $projectRoot "Source\Scripts\MMEDwemerArmor.psc") -Raw
$registry = Get-Content -LiteralPath (Join-Path $projectRoot "Source\Scripts\MMECustomArmorRegistry.psc") -Raw
$armor = Get-Content -LiteralPath (Join-Path $projectRoot "Source\Scripts\MMEArmorScript.psc") -Raw
$skyrimNet = Get-Content -LiteralPath (Join-Path $projectRoot "Source\Scripts\MMEAlertsSkyrimNet.psc") -Raw
$thoughts = Get-Content -LiteralPath (Join-Path $projectRoot "Source\Scripts\MMEThoughts.psc") -Raw
$reminder = Get-Content -LiteralPath (Join-Path $projectRoot "Source\Scripts\MMEServiceArmorReminder.psc") -Raw
$controller = Get-Content -LiteralPath (Join-Path $projectRoot "Source\Scripts\MMEAlertsController.psc") -Raw
$build = Get-Content -LiteralPath (Join-Path $projectRoot "build-package.ps1") -Raw
$stories = Get-Content -LiteralPath (Join-Path $projectRoot "SKSE\Plugins\StorageUtilData\MMEAlerts\DwemerArmorStories.json") -Raw | ConvertFrom-Json

function Assert-Contract([bool]$condition, [string]$message) {
    if (!$condition) { throw "FAIL: $message" }
    Write-Host "PASS: $message" -ForegroundColor Green
}

Assert-Contract ($registry -match 'Return "dwemer_forms"' -and $registry -match 'Return "dwemer_names"' -and $registry -match 'Return "Dwemer Armor"') "registry defines independent class-4 keys and label"
Assert-Contract ($registry -match 'While armorClass <= 4') "registry audit and lookup include class 4"
Assert-Contract ($controller -match 'RegisterForModEvent\("MME_MilkCycleComplete", "OnMMEMilkCycleComplete"\)' -and $controller -match 'MMEDwemerArmor\.ProcessNearbyDwemerArmor\(\)') "Dwemer system is driven by MME production completion"
Assert-Contract ($dwemer -match 'MME_Storage\.getMilkMaximum\(candidate\)' -and $dwemer -match 'maximumMilk \* 0\.90') "threshold uses MME maximum at exactly 90 percent"
Assert-Contract ($dwemer -match 'milkController\.Milking\(candidate, 0, 4, 0\)') "core transaction uses MME external Mode 4"
Assert-Contract ($dwemer -match 'standingmilkinganimations' -and $dwemer -match 'IdleForceDefaultState') "sequence reuses and cleans up MME standing animations"
Assert-Contract ($controller -match 'MMEDwemerArmor\.HandleMMEMilkingStart\(milkMaid\)' -and $dwemer -match 'standing animation dispatched from MME start') "standing animation is dispatched after MME resets its animation state"
Assert-Contract ($dwemer -match 'Function StoryDAS\(' -and $dwemer -match 'Function StoryDAE\(') "dedicated Dwemer start and end story functions exist"
Assert-Contract ($dwemer -match 'MMEStoryPopup\.ShowRandomStoryPopup\(Game\.GetPlayer\(\), GetConfigFile\(\), poolName' -and $dwemer -match 'dwemerarmorstart' -and $dwemer -match 'dwemerarmorend') "story lookup uses the shared facade with dedicated stable keys"
Assert-Contract ($dwemer -match 'MMELog\.MasterDiagnostic\("\[MME Extensions Dwemer Armor\]') "ordinary footprints use the master Papyrus logging toggle"
Assert-Contract ($dwemer -match 'Game\.GetFormFromFile\(0x0005D608, "Skyrim\.esm"\) as EffectShader') "Dwemer milking resolves vanilla EnchBlueFXShader"
Assert-Contract ($dwemer -match 'activationShader\.Play\(candidate, 5\.0\)') "Dwemer milking starts the blue activation shader before dispatch"
Assert-Contract ($dwemer -match 'activationShader\.Stop\(candidate\)') "Dwemer sequence cleanup stops the activation shader"
$shaderPreludeIndex = $dwemer.IndexOf('Utility.Wait(5.0)')
$milkingDispatchIndex = $dwemer.IndexOf('milkController.Milking(candidate, 0, 4, 0)')
Assert-Contract ($shaderPreludeIndex -ge 0 -and $milkingDispatchIndex -gt $shaderPreludeIndex) "Dwemer blue activation receives its full prelude before milking dispatch"
Assert-Contract ($dwemer -match 'blue activation shader unavailable') "missing blue shader uses the smoke-alarm channel"
Assert-Contract ($dwemer -notmatch 'SkyrimNetApi|DirectNarration|SendContext') "future Skyrim.Net narration is not implemented early"
Assert-Contract ($armor -match 'If armorClass == 4[\s\S]*reaction delegated to dedicated Dwemer Armor system') "ordinary equip reactions delegate class 4"
Assert-Contract ($skyrimNet -match 'armorClass == 0 \|\| armorClass == 4') "existing Skyrim.Net armor routes exclude class 4"
Assert-Contract ($thoughts -match 'If armorClass == 4' -and $reminder -match 'If armorClass == 4' -and $reminder -match 'serviceRole != "Blacksmith"') "thoughts exclude class 4 while reminders reserve it for blacksmiths"
Assert-Contract ($controller -match 'MMEDwemerArmor\.ValidateConfiguration\(\)' -and $controller -match 'MMEDwemerArmor\.HandleArmorRemoved\(') "controller validates and forwards removal to the dedicated service"
Assert-Contract ($stories.stringList.dwemerarmorstart.Count -gt 0 -and $stories.stringList.dwemerarmorend.Count -gt 0) "Dwemer story JSON uses MME typed stringList start and end pools"
Assert-Contract ($dwemer -notmatch 'threshold skipped \| already latched' -and $dwemer -match 'legacy threshold latch cleared') "legacy threshold latches cannot block later valid cycles"
Assert-Contract ($build -match '"MMEDwemerArmor"' -and $build -match '"DwemerArmorStories\.json"') "release build packages the Dwemer script and story JSON"
