param(
    [Parameter(Mandatory = $true)][string]$InputPath,
    [Parameter(Mandatory = $true)][string]$OutputPath
)

$ErrorActionPreference = "Stop"
$encoding = [System.Text.Encoding]::ASCII
$bytes = [System.IO.File]::ReadAllBytes((Resolve-Path -LiteralPath $InputPath))

function Replace-FixedAscii([byte[]]$source, [string]$oldText, [string]$newText) {
    $oldBytes = $encoding.GetBytes($oldText)
    $newBytes = $encoding.GetBytes($newText)
    if ($newBytes.Length -gt $oldBytes.Length) {
        throw "Replacement is longer than its existing plugin field: $newText"
    }

    $matchOffset = -1
    $matchCount = 0
    for ($i = 0; $i -le $source.Length - $oldBytes.Length; $i++) {
        $matches = $true
        for ($j = 0; $j -lt $oldBytes.Length; $j++) {
            if ($source[$i + $j] -ne $oldBytes[$j]) {
                $matches = $false
                break
            }
        }
        if ($matches) {
            $matchOffset = $i
            $matchCount++
        }
    }
    if ($matchCount -ne 1) {
        throw "Expected one exact plugin field for '$oldText'; found $matchCount."
    }

    for ($j = 0; $j -lt $oldBytes.Length; $j++) {
        if ($j -lt $newBytes.Length) {
            $source[$matchOffset + $j] = $newBytes[$j]
        } else {
            $source[$matchOffset + $j] = 0x20
        }
    }
}

Replace-FixedAscii $bytes "Displays MME Extensions' final custom milk speed penalty." "Movement speed reduced by <mag>%."
Replace-FixedAscii $bytes "Displays MME Extensions' final custom milk carry-weight penalty." "Carried milk reduces carry capacity by <mag> points."

$resolvedOutput = [System.IO.Path]::GetFullPath($OutputPath)
[System.IO.File]::WriteAllBytes($resolvedOutput, $bytes)
Write-Host "Patched Body effect descriptions without changing plugin size: $resolvedOutput"
