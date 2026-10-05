$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$registryPath = Join-Path $projectRoot "Source\Scripts\MMECustomArmorRegistry.psc"
$registry = Get-Content -LiteralPath $registryPath -Raw
$armor = Get-Content -LiteralPath (Join-Path $projectRoot "Source\Scripts\MMEArmorScript.psc") -Raw
$controller = Get-Content -LiteralPath (Join-Path $projectRoot "Source\Scripts\MMEAlertsController.psc") -Raw
$api = Get-Content -LiteralPath (Join-Path $projectRoot "Source\Scripts\MMEExtensionsAPI.psc") -Raw
$native = Get-Content -LiteralPath (Join-Path $projectRoot "src\Plugin.cpp") -Raw
$build = Get-Content -LiteralPath (Join-Path $projectRoot "build-package.ps1") -Raw
$quickStart = Get-Content -LiteralPath (Join-Path $projectRoot "fomod\choices\recommended-quickstart\Source\Scripts\MMEAlertsQuickTest.psc") -Raw
$config = Get-Content -LiteralPath (Join-Path $projectRoot "SKSE\Plugins\StorageUtilData\MMEAlerts\CustomArmorRegistry.json") -Raw | ConvertFrom-Json

function Assert-Contract([bool]$condition, [string]$message) {
    if (!$condition) { throw "FAIL: $message" }
    Write-Host "PASS: $message" -ForegroundColor Green
}

Assert-Contract (($config.dwemer_forms | Where-Object { $_ -like "DwarvenDeviousCuirass.esp|2048|Dwarven Devious Cuirass*" }).Count -eq 1) "unenchantable Dwarven cuirass defaults to independent Dwemer Armor"
Assert-Contract (($config.living_forms | Where-Object { $_ -like "DwarvenDeviousCuirass.esp|2048|*" }).Count -eq 0) "Dwarven cuirass is isolated from Living Armor"
Assert-Contract (($config.dwemer_forms | Where-Object { $_ -like "DwarvenDeviousCuirass.esp|2058|*" }).Count -eq 0) "enchanted Dwarven cuirass remains unsupported"
Assert-Contract ($registry -match 'StorageUtil\.FormListAdd\(None, GetDwemerArtisanKey\(\), targetArmor, False\)' -and $registry -match 'StorageUtil\.FormListRemove\(None, GetDwemerArtisanKey\(\), targetArmor, True\)') "artisan attachments use exact save-persistent forms"
Assert-Contract ($registry -match 'StringListClear\(GetConfigFile\(\), "dwemer_artisan_names"\)') "unsafe legacy display-name attachments are migrated away"
Assert-Contract ($registry -notmatch 'MME_FreeMaidSlots <= 0' -and $registry -match 'dedicated player slot') "player armor conversion preserves MilkQUEST MilkMaid[0] semantics"
Assert-Contract ($registry -match 'If wearer != Game\.GetPlayer\(\)') "custom armor equip conversion is player-only"
Assert-Contract ($registry -match 'NPC equip cannot create Milk Maid') "blocked NPC equip conversion leaves a master-trace footprint"
Assert-Contract ($registry -match 'MMELog\.MasterDiagnostic\("\[MME Extensions Custom Armor\]') "normal footprints use master Papyrus logging"
Assert-Contract ($registry -match 'MMELog\.Alarm\("\[MME Extensions Custom Armor\]') "configuration and persistence failures use smoke alarms"
Assert-Contract ($registry -match 'MilkForSprigganPassive' -and $registry -match 'setLactacidCurrent\(wearer, 1\.0\)') "Living and Parasite armor reproduce MME passive and Lactacid effects"
Assert-Contract ($registry -match 'Function HandleCustomArmorUnequipped' -and $registry -match 'RemoveSpell\(milkController\.MilkForSprigganPassive\)') "unequip cleanup removes the living passive"
Assert-Contract ($registry -match 'Function UnregisterArmor\(' -and $registry -match 'Function UnregisterArmorName\(') "registry supports exact and name removal"
Assert-Contract ($armor -match 'Function ClassifyOriginalArmor' -and $armor -match 'MMECustomArmorRegistry\.ClassifyCustomArmor') "custom classification layers after original MME classification"
Assert-Contract ($native -match 'MMEExtensions_ArmorUnequipped' -and $native -match 'SendArmorEvent\(actor, item, event->equipped\)') "native bridge publishes equip and unequip"
Assert-Contract ($controller -match 'RegisterForModEvent\("MMEExtensions_ArmorUnequipped", "OnArmorUnequipped"\)') "controller subscribes to native unequip"
Assert-Contract ($controller -match 'MMECustomArmorRegistry\.HandleCustomArmorEquipped' -and $controller -match 'MMECustomArmorRegistry\.HandleCustomArmorUnequipped') "controller delegates both armor transitions"
Assert-Contract ($api -match 'Return 11' -and $api -match 'Function IsCustomDwemerArmor\(' -and $api -match 'Function RegisterCustomArmor\(' -and $api -match 'Function UnregisterCustomArmor\(') "public API version 11 retains generic Dwemer registry calls"
Assert-Contract ($api -match 'Function InstallDwemerAttachment\(' -and $api -match 'Function RemoveDwemerAttachment\(' -and $api -match 'Function HasDwemerAttachment\(') "public API exposes reversible artisan Dwemer attachments"
Assert-Contract ($build -match '"MMECustomArmorRegistry"' -and $build -match '"CustomArmorRegistry\.json"') "build packages the registry script and JSON"
Assert-Contract ($quickStart -match 'Game\.GetModByName\(pluginName\) == 255' -and $quickStart -match 'DwarvenDeviousCuirass\.esp') "Quick Start keeps Dwarven Devious Cuirass optional"
Assert-Contract ($quickStart -match 'Game\.GetFormFromFile\(0x000800, pluginName\)' -and $quickStart -notmatch 'Game\.GetFormFromFile\(0x00080A, pluginName\)') "Quick Start grants only the unenchanted Dwarven cuirass"
