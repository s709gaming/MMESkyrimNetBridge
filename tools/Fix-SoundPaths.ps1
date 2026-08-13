$ErrorActionPreference = 'Stop'
$pluginPath = Join-Path (Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)) 'MMEAlert.esp'
$bytes = [IO.File]::ReadAllBytes($pluginPath)
$oldPrefix = [Text.Encoding]::ASCII.GetBytes('Data\Sound\')
$replacement = New-Object byte[] $oldPrefix.Length
$newPrefix = [Text.Encoding]::ASCII.GetBytes('fx\')
$newPrefix.CopyTo($replacement, 0)
$changed = 0

for ($i = 0; $i -le $bytes.Length - $oldPrefix.Length; $i++) {
    $match = $true
    for ($j = 0; $j -lt $oldPrefix.Length; $j++) {
        if ($bytes[$i + $j] -ne $oldPrefix[$j]) { $match = $false; break }
    }
    if ($match) {
        $replacement.CopyTo($bytes, $i)
        $changed++
        $i += $oldPrefix.Length - 1
    }
}

if ($changed -eq 0) {
    Write-Host 'Sound paths were already corrected.'
} else {
    [IO.File]::WriteAllBytes($pluginPath, $bytes)
    Write-Host "Corrected $changed sound path(s) to be relative to Data\Sound."
}
