$ErrorActionPreference = 'Stop'
& python -B (Join-Path $PSScriptRoot 'test_estrus_fomod.py')
if ($LASTEXITCODE) { throw 'Unified optional installer/pregnancy compatibility checks failed' }
Write-Host 'PASS: author-style Unified backend selection, preserved fallback, compiled pairs and native retirement'
