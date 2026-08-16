param(
    [string]$GameDataPath = "",
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"

function Add-CandidatePath {
    param(
        [System.Collections.Generic.List[string]]$List,
        [string]$Path
    )

    if ([string]::IsNullOrWhiteSpace($Path)) {
        return
    }
    if (!$List.Contains($Path)) {
        $List.Add($Path)
    }
}

function Resolve-GameDataPath {
    param([string]$UserPath)

    if (![string]::IsNullOrWhiteSpace($UserPath)) {
        if (Test-Path -LiteralPath $UserPath) {
            return $UserPath
        }
        throw "Game Data path not found: $UserPath"
    }

    $candidates = New-Object 'System.Collections.Generic.List[string]'

    Add-CandidatePath -List $candidates -Path $env:SKYRIM_SE_DATA_PATH
    Add-CandidatePath -List $candidates -Path $env:SKYRIM_DATA_PATH

    $registryRoots = @(
        "HKLM:\SOFTWARE\WOW6432Node\Bethesda Softworks\Skyrim Special Edition",
        "HKLM:\SOFTWARE\Bethesda Softworks\Skyrim Special Edition"
    )
    foreach ($regRoot in $registryRoots) {
        try {
            $installedPath = (Get-ItemProperty -Path $regRoot -ErrorAction Stop).'Installed Path'
            if (![string]::IsNullOrWhiteSpace($installedPath)) {
                Add-CandidatePath -List $candidates -Path (Join-Path $installedPath "Data")
            }
        }
        catch {
        }
    }

    $steamRoots = @(
        (Join-Path ${env:ProgramFiles(x86)} "Steam"),
        (Join-Path $env:ProgramFiles "Steam"),
        (Join-Path $env:LOCALAPPDATA "Programs\Steam")
    )

    foreach ($steamRoot in $steamRoots) {
        if (!(Test-Path -LiteralPath $steamRoot)) {
            continue
        }

        Add-CandidatePath -List $candidates -Path (Join-Path $steamRoot "steamapps\common\Skyrim Special Edition\Data")

        $libraryVdf = Join-Path $steamRoot "steamapps\libraryfolders.vdf"
        if (Test-Path -LiteralPath $libraryVdf) {
            $lines = Get-Content -LiteralPath $libraryVdf
            foreach ($line in $lines) {
                if ($line -match '"path"\s+"([^"]+)"') {
                    $libraryPath = $matches[1] -replace "\\\\", "\\"
                    Add-CandidatePath -List $candidates -Path (Join-Path $libraryPath "steamapps\common\Skyrim Special Edition\Data")
                }
            }
        }
    }

    foreach ($candidate in $candidates) {
        if (Test-Path -LiteralPath $candidate) {
            return $candidate
        }
    }

    throw "Could not auto-detect Skyrim Data path. Pass -GameDataPath explicitly, for example: -GameDataPath 'E:\Steam\steamapps\common\Skyrim Special Edition\Data'"
}

function Remove-IfExists {
    param(
        [string]$TargetPath,
        [string]$Label,
        [switch]$Directory
    )

    if (Test-Path -LiteralPath $TargetPath) {
        if ($DryRun) {
            Write-Host "[DRY RUN] Would remove ${Label}: $TargetPath" -ForegroundColor Yellow
            return
        }

        if ($Directory) {
            Remove-Item -LiteralPath $TargetPath -Recurse -Force
        }
        else {
            Remove-Item -LiteralPath $TargetPath -Force
        }
        Write-Host "Removed ${Label}: $TargetPath" -ForegroundColor Green
    }
    else {
        Write-Host "Not found (already clean): $TargetPath" -ForegroundColor DarkGray
    }
}

$GameDataPath = Resolve-GameDataPath -UserPath $GameDataPath

Write-Host "Cleaning MME Extensions leftovers from: $GameDataPath" -ForegroundColor Cyan

$paths = @(
    @{ Path = (Join-Path $GameDataPath "MMEAlert.esp"); Label = "Plugin"; IsDir = $false },
    @{ Path = (Join-Path $GameDataPath "MMEAlert_DISTR.ini"); Label = "SPID config"; IsDir = $false },
    @{ Path = (Join-Path $GameDataPath "SEQ\MMEAlert.seq"); Label = "SEQ file"; IsDir = $false },
    @{ Path = (Join-Path $GameDataPath "Scripts\MMEAlertsController.pex"); Label = "Script"; IsDir = $false },
    @{ Path = (Join-Path $GameDataPath "Scripts\MMEAlertsFlatRateDefaults.pex"); Label = "Script"; IsDir = $false },
    @{ Path = (Join-Path $GameDataPath "Scripts\MMEAlertsMCM.pex"); Label = "Script"; IsDir = $false },
    @{ Path = (Join-Path $GameDataPath "Scripts\MMEAlertsPlayerEffect.pex"); Label = "Script"; IsDir = $false },
    @{ Path = (Join-Path $GameDataPath "Scripts\MMEAlertsQuickTest.pex"); Label = "Script"; IsDir = $false },
    @{ Path = (Join-Path $GameDataPath "Scripts\MMEAlertsSkyrimNet.pex"); Label = "Script"; IsDir = $false },
    @{ Path = (Join-Path $GameDataPath "Scripts\MMEArousalBridge.pex"); Label = "Script"; IsDir = $false },
    @{ Path = (Join-Path $GameDataPath "Scripts\MMEDebug.pex"); Label = "Script"; IsDir = $false },
    @{ Path = (Join-Path $GameDataPath "Scripts\MMEDrinkTracker.pex"); Label = "Script"; IsDir = $false },
    @{ Path = (Join-Path $GameDataPath "Scripts\MMEExtensionsNative.pex"); Label = "Script"; IsDir = $false },
    @{ Path = (Join-Path $GameDataPath "Scripts\MMEMilkBoost.pex"); Label = "Script"; IsDir = $false },
    @{ Path = (Join-Path $GameDataPath "Scripts\MMEMilkDrinkEffects.pex"); Label = "Script"; IsDir = $false },
    @{ Path = (Join-Path $GameDataPath "Scripts\MMENPCDialog.pex"); Label = "Script"; IsDir = $false },
    @{ Path = (Join-Path $GameDataPath "Scripts\MMESkyrimNetVoiceControls.pex"); Label = "Script"; IsDir = $false },
    @{ Path = (Join-Path $GameDataPath "SKSE\Plugins\MMEExtensions.dll"); Label = "Native DLL"; IsDir = $false },
    @{ Path = (Join-Path $GameDataPath "SKSE\Plugins\StorageUtilData\MMEAlerts\Installer.json"); Label = "Installer config"; IsDir = $false },
    @{ Path = (Join-Path $GameDataPath "SKSE\Plugins\StorageUtilData\MMEAlerts\SkyrimNet.json"); Label = "SkyrimNet config"; IsDir = $false },
    @{ Path = (Join-Path $GameDataPath "SKSE\Plugins\SkyrimNet\prompts\submodules\character_bio\0260_mme_extensions_milkmaid.prompt"); Label = "SkyrimNet prompt"; IsDir = $false },
    @{ Path = (Join-Path $GameDataPath "Sound\fx\MMESkyrimNetBridge"); Label = "Sound folder"; IsDir = $true }
)

foreach ($entry in $paths) {
    Remove-IfExists -TargetPath $entry.Path -Label $entry.Label -Directory:$entry.IsDir
}

# Remove empty MMEAlerts config folder if cleanup left it empty.
$mmeAlertsConfigDir = Join-Path $GameDataPath "SKSE\Plugins\StorageUtilData\MMEAlerts"
if (Test-Path -LiteralPath $mmeAlertsConfigDir) {
    $remaining = Get-ChildItem -LiteralPath $mmeAlertsConfigDir -Force
    if ($remaining.Count -eq 0) {
        if ($DryRun) {
            Write-Host "[DRY RUN] Would remove empty folder: $mmeAlertsConfigDir" -ForegroundColor Yellow
        }
        else {
            Remove-Item -LiteralPath $mmeAlertsConfigDir -Force
            Write-Host "Removed empty folder: $mmeAlertsConfigDir" -ForegroundColor Green
        }
    }
}

Write-Host ""
if ($DryRun) {
    Write-Host "Dry run complete. No files were deleted." -ForegroundColor Cyan
}
else {
    Write-Host "Cleanup complete." -ForegroundColor Cyan
}
Write-Host "Tip: Use a fresh save for QuickStart validation after redeploy." -ForegroundColor DarkCyan
