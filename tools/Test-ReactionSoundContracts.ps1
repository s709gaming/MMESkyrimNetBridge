$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$resolver = Get-Content -Raw (Join-Path $projectRoot 'Source\Scripts\MMEReactionSounds.psc')
$poolScript = Get-Content -Raw (Join-Path $projectRoot 'tools\CreateMMEAlertMinimalSounds.pas')
$routedScripts = @(
    'MMEAlertsController.psc',
    'MMEArmorScript.psc',
    'MMEMilkDrinkEffects.psc',
    'MMETentacleEffects.psc',
    'MMEThoughts.psc'
)

function Assert-Contract([bool]$condition, [string]$message) {
    if (!$condition) { throw "FAIL: $message" }
    Write-Host "PASS: $message" -ForegroundColor Green
}

$markerContracts = @(
    @{ Tier = 'Mild'; Descriptor = '000896'; Marker = '000899' },
    @{ Tier = 'Medium'; Descriptor = '000897'; Marker = '00089A' },
    @{ Tier = 'Hot'; Descriptor = '000898'; Marker = '00089B' }
)
foreach ($contract in $markerContracts) {
    $stableIds = $poolScript.Contains("MMEAlerts_SNDR_Male_$($contract.Tier)', `$$($contract.Descriptor)") -and
        $poolScript.Contains("MMEAlerts_SOUN_Male_$($contract.Tier)', `$$($contract.Marker)")
    Assert-Contract $stableIds "male $($contract.Tier.ToLowerInvariant()) descriptor and marker keep stable FormIDs"
    Assert-Contract ($resolver.Contains("0x$($contract.Marker)")) "resolver references the male $($contract.Tier.ToLowerInvariant()) marker"
}

Assert-Contract ($resolver.Contains('sourceBase.GetSex() != 0')) 'only male actors switch away from the existing pools'
Assert-Contract ($poolScript.Contains('(MasterCount(TargetFile) shl 24) or aLocalFormID')) 'FormID collision checks use MMEAlert local-ID space'
Assert-Contract ($poolScript.Contains('FixedFormID(aRecord) and $00FFFFFF')) 'record identity comparisons use xEdit file-local FormIDs'
foreach ($scriptName in $routedScripts) {
    $source = Get-Content -Raw (Join-Path $projectRoot "Source\Scripts\$scriptName")
    Assert-Contract ($source.Contains('MMEReactionSounds.')) "$scriptName routes reaction playback through the sex-aware resolver"
}
