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
$suitNarration = Get-Content -LiteralPath (Join-Path $projectRoot "SKSE\Plugins\StorageUtilData\MMEAlerts\DwemerSuitNarration.json") -Raw | ConvertFrom-Json
$attachmentNarration = Get-Content -LiteralPath (Join-Path $projectRoot "SKSE\Plugins\StorageUtilData\MMEAlerts\DwemerAttachmentNarration.json") -Raw | ConvertFrom-Json
$selfMilking = Get-Content -LiteralPath (Join-Path $projectRoot "Source\Scripts\MMESelfMilking.psc") -Raw
$introduction = Get-Content -LiteralPath (Join-Path $projectRoot "Source\Scripts\MMEArmorIntroduction.psc") -Raw

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
Assert-Contract ($dwemer -notmatch 'SkyrimNetApi|DirectNarration' -and $dwemer -match 'NarrateDwemerSuitEvent\(candidate, narrationArmor, "milkingStart"\)' -and $dwemer -match 'NarrateDwemerSuitEvent\(candidate, narrationArmor, "milkingEnd"\)') "Dwemer milking delegates profiled start and successful end narration to the Skyrim.Net boundary"
Assert-Contract ($armor -match 'If armorClass == 4[\s\S]*reaction delegated to dedicated Dwemer Armor system') "ordinary equip reactions delegate class 4"
Assert-Contract ($skyrimNet -match 'armorClass == 0 \|\| armorClass == 4') "existing Skyrim.Net armor routes exclude class 4"
Assert-Contract ($thoughts -match 'If armorClass == 4' -and $reminder -match 'If armorClass == 4' -and $reminder -match 'serviceRole != "Blacksmith"') "thoughts exclude class 4 while reminders reserve it for blacksmiths"
Assert-Contract ($controller -match 'MMEDwemerArmor\.ValidateConfiguration\(\)' -and $controller -match 'MMEDwemerArmor\.HandleArmorRemoved\(') "controller validates and forwards removal to the dedicated service"
Assert-Contract ($stories.stringList.dwemerarmorstart.Count -gt 0 -and $stories.stringList.dwemerarmorend.Count -gt 0) "Dwemer story JSON uses MME typed stringList start and end pools"
Assert-Contract ($suitNarration.core -and $suitNarration.firstEquip -and $suitNarration.reequip -and $suitNarration.milkingStart -and $suitNarration.milkingEnd) "Dwemer suit JSON provides core lore and all four event prompts"
Assert-Contract ($attachmentNarration.core -and $attachmentNarration.firstEquip -and $attachmentNarration.reequip -and $attachmentNarration.milkingStart -and $attachmentNarration.milkingEnd) "Dwemer attachment JSON provides core lore and all four event prompts"
Assert-Contract ($registry -match 'Function GetDwemerPresentationProfile' -and $registry -match 'parts\[3\] == "deviousSuit"' -and $registry -match 'Return "artisanAttachment"') "only explicitly profiled full suits receive devious-suit presentation"
Assert-Contract ($attachmentNarration.core -match 'does not bind her arms' -and $attachmentNarration.core -match 'or transform the armor into a full restraint suit') "attachment lore explicitly rejects full-suit restraint anatomy"
Assert-Contract ($skyrimNet -match 'GetSex\(\) != 1' -and $skyrimNet -match 'ActorTypeNPC' -and $skyrimNet -match 'DirectNarration\(prompt, wearer, Game\.GetPlayer\(\)\)') "Dwemer suit narration accepts adult female humanoids and preserves the affected NPC as speaker"
Assert-Contract ($skyrimNet -match 'OnDwemerSuitPlayerLine' -and $controller -match 'Function OnDwemerSuitPlayerLine') "player Dwemer narration uses the private player-TTS callback"
Assert-Contract ($introduction -match 'NarrateDwemerSuitEvent\(target, equippedArmor, "firstEquip"\)' -and $introduction -match 'GetDwemerProfileMarkerKey' -and $controller -match 'dwemerEquipEvent = "reequip"') "profile-specific first equip and familiar re-equip have distinct narration routes"
Assert-Contract ($controller -match 'generic milking_start suppressed' -and $controller -match 'generic milking_end suppressed') "dedicated Dwemer milking suppresses duplicate generic narration"
Assert-Contract ($selfMilking -match 'Function StartCompatible' -and $selfMilking -match 'armorClass == 4' -and $selfMilking -match 'armorClass == 2 \|\| armorClass == 3') "automatic self-milking retains Dwemer, Living, and Parasite armor"
Assert-Contract ($dwemer -notmatch 'threshold skipped \| already latched' -and $dwemer -match 'legacy threshold latch cleared') "legacy threshold latches cannot block later valid cycles"
Assert-Contract ($build -match '"MMEDwemerArmor"' -and $build -match '"DwemerArmorStories\.json"' -and $build -match '"DwemerSuitNarration\.json"' -and $build -match '"DwemerAttachmentNarration\.json"') "release build packages both Dwemer presentation profiles"
