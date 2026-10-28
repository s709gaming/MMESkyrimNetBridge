param(
    [Parameter(Mandatory = $true)][string]$InputPath,
    [Parameter(Mandatory = $true)][string]$OutputPath
)
$ErrorActionPreference = 'Stop'
# Record-aware replacement for the former padded ASCII patch.
& dotnet run --project (Join-Path $PSScriptRoot 'body-display-builder') -- $InputPath $OutputPath
if ($LASTEXITCODE) { throw 'Body display description patch/round-trip validation failed' }
