$ErrorActionPreference = "Stop"
$projectRoot = Split-Path -Parent $PSScriptRoot
$baseSource = Get-Content -Raw (Join-Path $projectRoot "Source\MMEDiagnosticOverrides\MilkQUEST.psc")
$baseSource = $baseSource.Replace("`r`n", "`n")
# Removing only diagnostic statements must recover the exact original source.
$restored = [regex]::Replace($baseSource, '(?m)^\s*If MilkForSpriggan == None\n[^\n]*MMEMilkingDiagnostics.AlarmOnce[^\n]*\n\s*EndIf\n', '')
$restored = [regex]::Replace($restored, '(?m)^\s*If JsonUtil.StringListCount\("/MME/Strings_Stories", StoryType \+ StoryState\) < 2\n[^\n]*MMEMilkingDiagnostics.AlarmOnce[^\n]*\n\s*EndIf\n', '')
$restored = [regex]::Replace($restored, '(?m)^[ \t]*MMEMilkingDiagnostics\.[^\n]*\n', '').TrimEnd()
$hasher = [Security.Cryptography.SHA256]::Create()
try {
    $digest = [BitConverter]::ToString($hasher.ComputeHash([Text.Encoding]::UTF8.GetBytes($restored))).Replace('-', '')
} finally { $hasher.Dispose() }
if ($digest -ne '2CD72B7F5DBF697D980FDCFAD28BBB202FEAA569021F2A7B8655FBF52D4C8983') {
    throw "Diagnostic override changed original MME behavior/source outside diagnostic hooks"
}
Write-Host "PASS: diagnostic removal recovers exact normalized original MilkQUEST source"
$helper = Get-Content -Raw (Join-Path $projectRoot "Source\Scripts\MMEMilkingDiagnostics.psc")
foreach ($required in @('enablePapyrusTrace', '300.0', '60.0', 'ArmorSnapshot', 'ResetWatchdogs')) {
    if (!$helper.Contains($required)) { throw "Missing diagnostic contract: $required" }
}
if ($helper -match 'RegisterForUpdate|RegisterForSingleUpdate|Utility\.Wait|DisablePlayerControls|RemoveSpell') {
    throw "Diagnostics must not add a timer, latent wait, or gameplay recovery"
}
Write-Host "PASS: master toggle, rate limiting, timeouts and reset; no new timer or gameplay recovery"
