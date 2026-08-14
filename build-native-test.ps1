$ErrorActionPreference = "Stop"

# Builds the optional native add-on separately from MMEAlert.zip. CommonLibSSE-NG
# is a build dependency; the eventual SkyrimNet API will be resolved at runtime.

# Use the Visual Studio installation that provides MSVC, CMake, and Ninja.
$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$vsRoot = "E:\Visual Studio"
$devShell = Join-Path $vsRoot "Common7\Tools\VsDevCmd.bat"
$cmake = Join-Path $vsRoot "Common7\IDE\CommonExtensions\Microsoft\CMake\CMake\bin\cmake.exe"
$ninjaDir = Join-Path $vsRoot "Common7\IDE\CommonExtensions\Microsoft\CMake\Ninja"

if (!(Test-Path -LiteralPath $devShell)) {
    throw "Visual Studio developer shell not found: $devShell"
}
if (!(Test-Path -LiteralPath $cmake)) {
    throw "CMake not found: $cmake"
}

# Import the x64 MSVC environment into this PowerShell process.
$environmentDump = cmd.exe /s /c "`"$devShell`" -arch=x64 -host_arch=x64 >nul && set"
foreach ($line in $environmentDump) {
    if ($line -match '^([^=]+)=(.*)$') {
        Set-Item -Path "Env:$($matches[1])" -Value $matches[2]
    }
}
$env:Path = "$ninjaDir;$env:Path"
$env:VCPKG_PLATFORM_TOOLSET = "v143"

Push-Location $projectRoot
try {
    & $cmake --preset release-msvc
    if ($LASTEXITCODE -ne 0) { throw "CMake configuration failed" }

    & $cmake --build --preset release-msvc
    if ($LASTEXITCODE -ne 0) { throw "Native plugin build failed" }

    $dll = Join-Path $projectRoot "build\native-release\package\SKSE\Plugins\MMEExtensions.dll"
    if (!(Test-Path -LiteralPath $dll)) { throw "Build completed without producing $dll" }

    # Create a Vortex-ready archive with SKSE/Plugins at its root.
    $zip = Join-Path $projectRoot "dist\MMEExtensionsNative.zip"
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $zip) | Out-Null
    if (Test-Path -LiteralPath $zip) {
        Remove-Item -LiteralPath $zip -Force
    }
    Compress-Archive `
        -Path (Join-Path $projectRoot "build\native-release\package\*") `
        -DestinationPath $zip `
        -CompressionLevel Optimal

    Write-Host ""
    Write-Host "Native test plugin built successfully:" -ForegroundColor Green
    Write-Host $dll
    Write-Host "Vortex package:"
    Write-Host $zip
} finally {
    Pop-Location
}
