$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$service = Get-Content -LiteralPath (Join-Path $projectRoot "Source\Scripts\MMEDwemerBlacksmithDialogue.psc") -Raw
$wrapper = Get-Content -LiteralPath (Join-Path $projectRoot "Source\Scripts\MMEBlacksmithDialogue.psc") -Raw
$reminder = Get-Content -LiteralPath (Join-Path $projectRoot "Source\Scripts\MMEServiceArmorReminder.psc") -Raw
$config = Get-Content -LiteralPath (Join-Path $projectRoot "SKSE\Plugins\StorageUtilData\MMEAlerts\ArmorCheckReminders.json") -Raw | ConvertFrom-Json
$build = Get-Content -LiteralPath (Join-Path $projectRoot "build-package.ps1") -Raw

function Assert-Contract([bool]$condition, [string]$message) {
    if (!$condition) { throw "FAIL: $message" }
    Write-Host "PASS: $message" -ForegroundColor Green
}

Assert-Contract ($service -match 'JobBlacksmithFaction|0x05091D' -and $service -match 'JobMerchantFaction|0x051596') "service requires a merchant blacksmith"
Assert-Contract ($service -match 'IsArtisanDwemerArmor' -and $service -match 'RegisterArtisanDwemerArmor' -and $service -match 'UnregisterArtisanDwemerArmor') "service manages only the dedicated artisan registry"
Assert-Contract ($service -match 'MMETimedArmorLock\.IsLocked' -and $service -match 'GetLockedArmor') "active timed armor is protected"
Assert-Contract ($service -match 'MMELog\.MasterDiagnostic' -and $service -match 'MMELog\.Alarm') "master footprints and smoke alarms are present"
Assert-Contract ($wrapper -match 'MMEExt_DwemerBlacksmithArmorState' -and $wrapper -match 'Fragment_InstallDwemerAttachment' -and $wrapper -match 'Fragment_RemoveDwemerAttachment') "Hey there wrapper exposes Dwemer state and fragments"
Assert-Contract ($reminder -match 'serviceRole != "Blacksmith"' -and $reminder -match 'poolName = "dwemerarmor"') "Dwemer reminder is blacksmith-only"
Assert-Contract ($config.dwemerarmor.Count -gt 0) "Dwemer reminder pool is populated"
foreach ($line in $config.dwemerarmor) {
    Assert-Contract ($line.Length -le 58) "Dwemer observation leaves HUD room for speaker and reaction: $line"
}
Assert-Contract ($build -match '"MMEDwemerBlacksmithDialogue"') "build compiles and packages the new service"
