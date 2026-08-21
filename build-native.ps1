param(
    [switch]$VR
)

$ErrorActionPreference = "Stop"

# Builds the CommonLibSSE-NG lifecycle DLL used by the complete mod package.

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
    $preset = if ($VR) { "vr-release-msvc" } else { "release-msvc" }
    $buildFolder = if ($VR) { "native-vr-release" } else { "native-release" }
    & $cmake --preset $preset
    if ($LASTEXITCODE -ne 0) { throw "CMake configuration failed" }

    & $cmake --build --preset $preset
    if ($LASTEXITCODE -ne 0) { throw "Native plugin build failed" }

    $dll = Join-Path $projectRoot "build\$buildFolder\package\SKSE\Plugins\MMEExtensions.dll"
    if (!(Test-Path -LiteralPath $dll)) { throw "Build completed without producing $dll" }

    Write-Host ""
    Write-Host "Native plugin built successfully:" -ForegroundColor Green
    Write-Host $dll
    Write-Host "Run build-package.bat to create the complete mod archive."
} finally {
    Pop-Location
}
