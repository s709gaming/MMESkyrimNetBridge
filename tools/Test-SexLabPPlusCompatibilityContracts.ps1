$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$standard = Get-Content -LiteralPath (Join-Path $root 'Source\Scripts\MMESexLabBreastfeedingBackend.psc') -Raw
$pplus = Get-Content -LiteralPath (Join-Path $root 'fomod\choices\sexlab-pplus\Source\Scripts\MMESexLabBreastfeedingBackend.psc') -Raw
$controller = Get-Content -LiteralPath (Join-Path $root 'Source\Scripts\MMEAlertsController.psc') -Raw
$debug = Get-Content -LiteralPath (Join-Path $root 'Source\Scripts\MMEDebug.psc') -Raw
$fomod = Get-Content -LiteralPath (Join-Path $root 'fomod\ModuleConfig.xml') -Raw
$choiceRoot = Join-Path $root 'fomod\choices\sexlab-pplus'
$registry = Get-Content -LiteralPath (Join-Path $choiceRoot 'SKSE\SexLab\Registry\Source\3jiouBreastFeeding.slsb.json') -Raw
$registryData = $registry | ConvertFrom-Json
$fnisList = Get-Content -LiteralPath (Join-Path $choiceRoot 'meshes\actors\character\animations\3jiouBreastFeeding\FNIS_3jiouBreastFeeding_List.txt')

function Assert-Contract([bool]$condition, [string]$message) {
    if (!$condition) { throw $message }
    Write-Host "PASS: $message"
}

Assert-Contract ($standard.Contains('zjBreastFeedingVar') -and $standard.Contains('zjBreastFeeding')) 'standard backend retains both original MME registrars'
Assert-Contract ($standard.Contains('StartBreastfeeding') -and $standard.Contains('IsBreastfeedingThread')) 'standard backend exposes the shared facade contract'
Assert-Contract (!$standard.Contains('SexLabThread') -and !$standard.Contains('StartSceneEx')) 'standard backend contains no P+-only API types'
Assert-Contract ($pplus.Contains('e4j6zbhk') -and $pplus.Contains('6otwp8mm')) 'P+ backend owns both converted SLSB scene IDs'
Assert-Contract ($pplus.Contains('StartSceneEx') -and $pplus.Contains('GetActiveScene')) 'P+ backend starts and recognizes SLSB scenes through the P+ API'
Assert-Contract ($controller.Contains('MMESexLabBreastfeedingBackend.IsAvailable')) 'controller delegates the shared MME dialogue gate to the selected backend'
Assert-Contract (!$controller.Contains('Bool straightFound = milkController.SexLab.AnimSlots.GetbyRegistrar')) 'controller no longer closes the gate from legacy registrar checks'
Assert-Contract ($debug.Contains('MMESexLabBreastfeedingBackend.StartBreastfeeding') -and $debug.Contains('MMESexLabBreastfeedingBackend.IsBreastfeedingThread')) 'SexLab starts and completions share the backend facade'
Assert-Contract (!$debug.Contains('String animationName = "zjBreastFeeding"')) 'common transaction no longer selects legacy animations directly'
Assert-Contract ($fomod.Contains('All-in-One SexLab P+ Compatibility')) 'FOMOD identifies the unified P+ compatibility option'
Assert-Contract ($fomod.Contains('Scripts\SexLabThread.pex') -and $fomod.Contains('Scripts\SexlabRegistry.pex')) 'FOMOD detects P+ from two framework-owned scripts'
Assert-Contract ($fomod.Contains('SKSE\CustomConsole\SexLabPPlus.yaml')) 'FOMOD has a P+-unique best-effort detection marker'
Assert-Contract ($fomod.Contains('<defaultType name="Optional" />')) 'P+ option remains manually selectable when Vortex cannot classify loose files as active'
Assert-Contract (!$fomod.Contains('fileDependency file="SKSE\SexLab\Registry\3jiouBreastFeeding.slr"')) 'FOMOD does not detect P+ from the registry it installs itself'
Assert-Contract ($fomod.Contains('fomod\choices\sexlab-pplus\Scripts\MMESexLabBreastfeedingBackend.pex')) 'FOMOD installs the P+ breastfeeding backend only through the P+ option'
Assert-Contract ($fomod.Contains('fomod\choices\sexlab-pplus\Scripts\MME_Dialogues.pex') -and $fomod.Contains('fomod\choices\sexlab-pplus\Scripts\MilkPlayerLoadGame.pex')) 'P+ option installs both approved MME compatibility overrides'
Assert-Contract ($fomod.Contains('fomod\choices\sexlab-pplus\meshes') -and $fomod.Contains('fomod\choices\sexlab-pplus\SKSE')) 'P+ option installs converted animations and SLSB registry'
Assert-Contract ((Test-Path -LiteralPath (Join-Path $choiceRoot 'Scripts\MME_Dialogues.pex')) -and (Test-Path -LiteralPath (Join-Path $choiceRoot 'Scripts\MilkPlayerLoadGame.pex'))) 'both approved compiled MME overrides are bundled'
Assert-Contract ((Get-ChildItem -LiteralPath (Join-Path $choiceRoot 'meshes\actors\character\animations\3jiouBreastFeeding') -Filter '*.HKX' -File).Count -eq 14) 'all fourteen converted breastfeeding animation files are bundled'
Assert-Contract ((Test-Path -LiteralPath (Join-Path $choiceRoot 'meshes\actors\character\behaviors\FNIS_3jiouBreastFeeding_Behavior.hkx')) -and (Test-Path -LiteralPath (Join-Path $choiceRoot 'SKSE\SexLab\Registry\3jiouBreastFeeding.slr'))) 'converted behavior and runtime SLSB registry are bundled'
Assert-Contract ($registry.Contains('e4j6zbhk') -and $registry.Contains('6otwp8mm')) 'bundled registry declares both scene IDs used by the P+ backend'
Assert-Contract ($registry.Contains('"submissive":true')) 'bundled registry retains the milk-source submissive role used for actor ordering'
Assert-Contract ($fomod.Contains('rerun FNIS or your compatible behavior generator')) 'FOMOD warns that P+ animations require behavior generation'
$registryEvents = @($registryData.scenes.PSObject.Properties.Value | ForEach-Object { $_.stages } | ForEach-Object { $_.positions } | ForEach-Object { $_.event })
$fnisEvents = @($fnisList | ForEach-Object { if ($_ -match '^b\s+j90d(\S+)\s+(\S+\.hkx)$') { $Matches[1] } })
Assert-Contract ($registryEvents.Count -eq 14 -and $fnisEvents.Count -eq 14) 'registry and FNIS list each declare all fourteen animation events'
foreach ($eventName in $registryEvents) {
    Assert-Contract ($fnisEvents -contains $eventName) "SLSB event $eventName has a matching FNIS behavior event"
}
Assert-Contract (Test-Path -LiteralPath (Join-Path $root 'docs\SEXLAB-PPLUS-COMPATIBILITY.md')) 'P+ credit, permission, and installation document is present'
