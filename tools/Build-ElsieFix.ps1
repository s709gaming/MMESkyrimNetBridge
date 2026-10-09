$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$elsiePlugin = "E:\Steam\SteamApps\common\Skyrim Special Edition\Data\CP_Elsie.esp"
$outputPlugin = Join-Path $projectRoot "fomod\choices\elsie-compatibility\MME Extensions - Elsie LaVache Fix.esp"
$builder = Join-Path $projectRoot "tools\elsie-fix-builder\elsie-fix-builder.csproj"

if (!(Test-Path -LiteralPath $elsiePlugin)) {
    throw "Elsie source plugin not found: $elsiePlugin"
}

& dotnet run --project $builder -- $elsiePlugin $outputPlugin
if ($LASTEXITCODE -ne 0) {
    throw "Elsie compatibility patch generation failed."
}

