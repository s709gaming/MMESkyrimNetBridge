$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
$jugsSource = "E:\Vortex Mods\skyrimse\JUGs\Scripts\Source"
$patchSource = Join-Path $projectRoot "fomod\choices\jugs-compatibility\Source\Scripts"

if (!(Test-Path -LiteralPath $jugsSource)) {
    throw "Installed JUGS source folder not found: $jugsSource"
}
New-Item -ItemType Directory -Force -Path $patchSource | Out-Null

$sceneSources = @(Get-ChildItem -LiteralPath $jugsSource -Filter "*.psc" | Where-Object {
    (Get-Content -LiteralPath $_.FullName -Raw) -match 'SexLab\.StartSex\(sexActors, anims\)'
})

foreach ($sourceFile in $sceneSources) {
    $scriptName = [IO.Path]::GetFileNameWithoutExtension($sourceFile.Name)
    $content = Get-Content -LiteralPath $sourceFile.FullName -Raw
    $guardedCall = "MMEJugsSafety.TryStart(SexLab, sexActors, anims, `"$scriptName`")"

    if ($content -match 'SexLab\.StartSex\(sexActors, anims\)\s*\r?\n\s*Jugs\.JugsSGOMilker\(([^\r\n]+)\)') {
        $arguments = $Matches[1]
        $replacement = "If $guardedCall`r`n    Jugs.JugsSGOMilker($arguments)`r`nEndIf"
        $content = [regex]::Replace($content, 'SexLab\.StartSex\(sexActors, anims\)\s*\r?\n\s*Jugs\.JugsSGOMilker\(([^\r\n]+)\)', $replacement, 1)
    } else {
        $content = $content -replace 'SexLab\.StartSex\(sexActors, anims\)', $guardedCall
    }

    Set-Content -LiteralPath (Join-Path $patchSource $sourceFile.Name) -Value $content -Encoding UTF8
}

Write-Host "Synchronized $($sceneSources.Count) guarded JUGS scene fragments."
