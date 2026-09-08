param(
    [string]$CompiledDirectory = (Join-Path (Split-Path -Parent $PSScriptRoot) 'Scripts'),
    [string]$Assembler = 'E:\Steam\steamapps\common\Skyrim Special Edition\Papyrus Compiler\PapyrusAssembler.exe'
)
$ErrorActionPreference = 'Stop'

# Inspect actual compiler output, not only source text. A None comparison can
# become CAST <array temporary> None; the VM rejects it and a reused temporary
# can still hold the native scan, making the following equality spuriously true.
$testDirectory = Join-Path ([IO.Path]::GetTempPath()) ('MME-ScanArrayTests-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $testDirectory | Out-Null
Push-Location $testDirectory
try {
    foreach ($scriptName in @('MMEAlertsController', 'MMETentacleEffects', 'MMEThoughts', 'MMEOStimIntegration')) {
        Copy-Item -LiteralPath (Join-Path $CompiledDirectory "$scriptName.pex") -Destination $testDirectory
        & $Assembler $scriptName -D -Q
        if ($LASTEXITCODE -ne 0) { throw "Disassembly failed: $scriptName" }
        $arrayVariables = @{}
        $inspectFunction = $false
        foreach ($line in Get-Content -LiteralPath "$scriptName.disassemble.pas") {
            if ($line -match '^\s*\.function\s+(\S+)') {
                $arrayVariables = @{}
                $inspectFunction = $scriptName -ne 'MMEAlertsController' -or $matches[1] -in @('OnUpdateGameTime', 'RunArmorInjectionCheckNow', 'ScanNearbyMilkMaids')
            }
            if ($line -match '^\s*\.(?:local|param)\s+(\S+)\s+\S+\[\]') {
                $arrayVariables[$matches[1]] = $true
            }
            if ($inspectFunction -and $line -match '^\s*Cast\s+(\S+)\s+None(?:\s|$)' -and $arrayVariables.ContainsKey($matches[1])) {
                throw "Invalid None-to-array cast in ${scriptName}: $($line.Trim())"
            }
        }
        Write-Host "PASS: $scriptName scan/content functions have no None-to-array casts"
    }
} finally {
    Pop-Location
    # Keep generated disassemblies for inspection; never touch installed files.
    Write-Host "Regression artifacts: $testDirectory"
}
