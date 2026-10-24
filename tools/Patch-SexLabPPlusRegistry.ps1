$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
$registryPath = Join-Path $projectRoot "fomod\choices\sexlab-pplus\SKSE\SexLab\Registry\3jiouBreastFeeding.slr"

if (!(Test-Path -LiteralPath $registryPath)) {
    throw "Compiled SexLab P+ registry is missing: $registryPath"
}

$bytes = [IO.File]::ReadAllBytes($registryPath)
$recordStarts = @()
for ($i = 0; $i -le $bytes.Length - 14; $i++) {
    if ($bytes[$i] -eq 0 -and
        ($bytes[$i + 1] -eq 7 -or $bytes[$i + 1] -eq 6) -and
        $bytes[$i + 2] -eq 0 -and $bytes[$i + 3] -eq 0 -and $bytes[$i + 4] -eq 3 -and $bytes[$i + 5] -eq 232 -and $bytes[$i + 6] -eq 1 -and
        $bytes[$i + 7] -eq 0 -and
        ($bytes[$i + 8] -eq 7 -or $bytes[$i + 8] -eq 5 -or $bytes[$i + 8] -eq 6) -and
        $bytes[$i + 9] -eq 0 -and $bytes[$i + 10] -eq 0 -and $bytes[$i + 11] -eq 3 -and $bytes[$i + 12] -eq 232 -and $bytes[$i + 13] -eq 0) {
        $recordStarts += $i
        $i += 13
    }
}

if ($recordStarts.Count -ne 2) {
    throw "Expected exactly two human two-position scene records in the compiled P+ registry; found $($recordStarts.Count). Re-export with SLSB before patching."
}

# SLSB sex bitfield: male=1, female=2, futa=4.
# Straight: female/futa milk source, male/futa drinker.
$bytes[$recordStarts[0] + 1] = 6
$bytes[$recordStarts[0] + 8] = 5
# Lesbian: female/futa milk source and drinker.
$bytes[$recordStarts[1] + 1] = 6
$bytes[$recordStarts[1] + 8] = 6

[IO.File]::WriteAllBytes($registryPath, $bytes)
Write-Host "Patched compiled SexLab P+ breastfeeding position constraints." -ForegroundColor Green
