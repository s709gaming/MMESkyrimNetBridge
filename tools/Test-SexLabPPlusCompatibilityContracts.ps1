$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$standard = Get-Content -LiteralPath (Join-Path $root 'Source\Scripts\MMESexLabBreastfeedingBackend.psc') -Raw
$pplus = Get-Content -LiteralPath (Join-Path $root 'fomod\choices\sexlab-pplus\Source\Scripts\MMESexLabBreastfeedingBackend.psc') -Raw
$standardSdk = Get-Content -LiteralPath (Join-Path $root 'tools\mme-sdk\sslThreadModel.psc') -Raw
$controller = Get-Content -LiteralPath (Join-Path $root 'Source\Scripts\MMEAlertsController.psc') -Raw
$debug = Get-Content -LiteralPath (Join-Path $root 'Source\Scripts\MMEDebug.psc') -Raw
$fomod = Get-Content -LiteralPath (Join-Path $root 'fomod\ModuleConfig.xml') -Raw
$choiceRoot = Join-Path $root 'fomod\choices\sexlab-pplus'
$registry = Get-Content -LiteralPath (Join-Path $choiceRoot 'SKSE\SexLab\Registry\Source\3jiouBreastFeeding.slsb.json') -Raw
$registryData = $registry | ConvertFrom-Json
$compiledRegistryPath = Join-Path $choiceRoot 'SKSE\SexLab\Registry\3jiouBreastFeeding.slr'
$compiledRegistry = [IO.File]::ReadAllBytes($compiledRegistryPath)
$fnisList = Get-Content -LiteralPath (Join-Path $choiceRoot 'meshes\actors\character\animations\3jiouBreastFeeding\FNIS_3jiouBreastFeeding_List.txt')

function Assert-Contract([bool]$condition, [string]$message) {
    if (!$condition) { throw $message }
    Write-Host "PASS: $message"
}

Assert-Contract ($standard.Contains('zjBreastFeedingVar') -and $standard.Contains('zjBreastFeeding')) 'standard backend retains both original MME registrars'
Assert-Contract ($standard.Contains('StartBreastfeeding') -and $standard.Contains('IsBreastfeedingThread')) 'standard backend exposes the shared facade contract'
Assert-Contract (!$standard.Contains('SexLabThread') -and !$standard.Contains('StartSceneEx')) 'standard backend contains no P+-only API types'
Assert-Contract ($standard.Contains('model.AddActor(milkSource, False, None, False)') -and $standard.Contains('model.AddActor(drinker, False, None, False)')) 'standard backend supplies SexLab 1.66d AddActor all four runtime arguments'
Assert-Contract ($standardSdk.Contains('Int Function AddActor(Actor actorRef, Bool isVictim = False, sslBaseVoice voice = None, Bool forceSilent = False)')) 'standard compile SDK mirrors SexLab 1.66d four-argument AddActor contract'
Assert-Contract ($pplus.Contains('e4j6zbhk') -and $pplus.Contains('6otwp8mm')) 'P+ backend owns both converted SLSB scene IDs'
Assert-Contract ($pplus.Contains('StartSceneEx') -and $pplus.Contains('GetActiveScene')) 'P+ backend starts and recognizes SLSB scenes through the P+ API'
Assert-Contract ($controller.Contains('MMESexLabBreastfeedingBackend.IsAvailable')) 'controller delegates the shared MME dialogue gate to the selected backend'
Assert-Contract (!$controller.Contains('Bool straightFound = milkController.SexLab.AnimSlots.GetbyRegistrar')) 'controller no longer closes the gate from legacy registrar checks'
Assert-Contract ($debug.Contains('MMESexLabBreastfeedingBackend.StartBreastfeeding') -and $debug.Contains('MMESexLabBreastfeedingBackend.IsBreastfeedingThread')) 'SexLab starts and completions share the backend facade'
Assert-Contract (!$debug.Contains('String animationName = "zjBreastFeeding"')) 'common transaction no longer selects legacy animations directly'
Assert-Contract ($fomod.Contains('All-in-One SexLab P+ Compatibility — READ INSTRUCTIONS CAREFULLY') -and $fomod.Contains('READ THE SEXLAB P+ INSTRUCTIONS CAREFULLY.')) 'FOMOD identifies the unified P+ compatibility option and keeps its warning visible'
[xml]$fomodXml = $fomod
$pplusChoices = @($fomodXml.SelectNodes("//plugin") | Where-Object { $_.GetAttribute("name").StartsWith("All-in-One SexLab P+") })
$pplusChoice = $pplusChoices[0]
Assert-Contract ($pplusChoices.Count -eq 1 -and $pplusChoice.SelectSingleNode("typeDescriptor/type").GetAttribute("name") -eq "Optional") 'P+ compatibility is an explicit optional user choice'
Assert-Contract ($null -eq $pplusChoice.typeDescriptor.dependencyType) 'P+ compatibility never becomes automatically required from unreliable file detection'
Assert-Contract (!$pplusChoice.description.Contains("detect")) 'P+ description makes no automatic-detection claim'
Assert-Contract (!$fomod.Contains('fileDependency file="SKSE\SexLab\Registry\3jiouBreastFeeding.slr"')) 'FOMOD does not detect P+ from the registry it installs itself'
Assert-Contract ($fomod.Contains('fomod\choices\sexlab-pplus\Scripts\MMESexLabBreastfeedingBackend.pex')) 'FOMOD installs the P+ breastfeeding backend only through the P+ option'
Assert-Contract ($fomod.Contains('fomod\choices\sexlab-pplus\Scripts\MME_Dialogues.pex') -and $fomod.Contains('fomod\choices\sexlab-pplus\Scripts\MilkPlayerLoadGame.pex')) 'P+ option installs both approved MME compatibility overrides'
Assert-Contract ($fomod.Contains('fomod\choices\sexlab-pplus\meshes') -and $fomod.Contains('fomod\choices\sexlab-pplus\SKSE')) 'P+ option installs converted animations and SLSB registry'
Assert-Contract ((Test-Path -LiteralPath (Join-Path $choiceRoot 'Scripts\MME_Dialogues.pex')) -and (Test-Path -LiteralPath (Join-Path $choiceRoot 'Scripts\MilkPlayerLoadGame.pex'))) 'both approved compiled MME overrides are bundled'
Assert-Contract ((Get-ChildItem -LiteralPath (Join-Path $choiceRoot 'meshes\actors\character\animations\3jiouBreastFeeding') -Filter '*.HKX' -File).Count -eq 14) 'all fourteen converted breastfeeding animation files are bundled'
Assert-Contract ((Test-Path -LiteralPath (Join-Path $choiceRoot 'meshes\actors\character\behaviors\FNIS_3jiouBreastFeeding_Behavior.hkx')) -and (Test-Path -LiteralPath (Join-Path $choiceRoot 'SKSE\SexLab\Registry\3jiouBreastFeeding.slr'))) 'converted behavior and runtime SLSB registry are bundled'
Assert-Contract ($registry.Contains('e4j6zbhk') -and $registry.Contains('6otwp8mm')) 'bundled registry declares both scene IDs used by the P+ backend'
Assert-Contract ($registryData.scenes.e4j6zbhk.positions[0].submissive -eq $true -and $registryData.scenes.'6otwp8mm'.positions[0].submissive -eq $true) 'bundled registry retains the milk-source submissive role used for actor ordering'
Assert-Contract (!$registryData.scenes.e4j6zbhk.positions[0].sex.male -and $registryData.scenes.e4j6zbhk.positions[0].sex.female -and $registryData.scenes.e4j6zbhk.positions[1].sex.male -and !$registryData.scenes.e4j6zbhk.positions[1].sex.female) 'straight scene constrains the source to female/futa and the drinker to male/futa'
Assert-Contract (!$registryData.scenes.'6otwp8mm'.positions[0].sex.male -and !$registryData.scenes.'6otwp8mm'.positions[1].sex.male) 'lesbian scene constrains both positions to female/futa actors'
Assert-Contract ($registryData.scenes.'6otwp8mm'.tags -contains 'lesbian' -and $registryData.scenes.'6otwp8mm'.tags -notcontains 'straight' -and $registryData.scenes.'6otwp8mm'.tags -notcontains 'mf') 'lesbian scene no longer advertises straight or MF tags'
Assert-Contract ($pplus.Contains('MMELog.MasterDiagnostic') -and $pplus.Contains('MMELog.Alarm')) 'P+ backend emits master-gated role footprints and smoke alarms'
$positionFlags = @()
for ($i = 0; $i -le $compiledRegistry.Length - 14; $i++) {
    if ($compiledRegistry[$i] -eq 0 -and $compiledRegistry[$i + 2] -eq 0 -and $compiledRegistry[$i + 3] -eq 0 -and $compiledRegistry[$i + 4] -eq 3 -and $compiledRegistry[$i + 5] -eq 232 -and $compiledRegistry[$i + 6] -eq 1 -and $compiledRegistry[$i + 7] -eq 0 -and $compiledRegistry[$i + 9] -eq 0 -and $compiledRegistry[$i + 10] -eq 0 -and $compiledRegistry[$i + 11] -eq 3 -and $compiledRegistry[$i + 12] -eq 232 -and $compiledRegistry[$i + 13] -eq 0) {
        $positionFlags += ,@($compiledRegistry[$i + 1], $compiledRegistry[$i + 8])
        $i += 13
    }
}
Assert-Contract ($positionFlags.Count -eq 2 -and $positionFlags[0][0] -eq 6 -and $positionFlags[0][1] -eq 5 -and $positionFlags[1][0] -eq 6 -and $positionFlags[1][1] -eq 6) 'compiled SLR enforces straight and lesbian milk-source/drinker sex roles'
Assert-Contract ($fomod.Contains('rerun FNIS or your compatible behavior generator')) 'FOMOD warns that P+ animations require behavior generation'
$registryEvents = @($registryData.scenes.PSObject.Properties.Value | ForEach-Object { $_.stages } | ForEach-Object { $_.positions } | ForEach-Object { $_.event })
$fnisEvents = @($fnisList | ForEach-Object { if ($_ -match '^b\s+j90d(\S+)\s+(\S+\.hkx)$') { $Matches[1] } })
Assert-Contract ($registryEvents.Count -eq 14 -and $fnisEvents.Count -eq 14) 'registry and FNIS list each declare all fourteen animation events'
foreach ($eventName in $registryEvents) {
    Assert-Contract ($fnisEvents -contains $eventName) "SLSB event $eventName has a matching FNIS behavior event"
}
Assert-Contract (Test-Path -LiteralPath (Join-Path $root 'docs\SEXLAB-PPLUS-COMPATIBILITY.md')) 'P+ credit, permission, and installation document is present'
