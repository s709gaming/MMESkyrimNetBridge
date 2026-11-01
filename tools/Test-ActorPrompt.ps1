$ErrorActionPreference='Stop'
$root=Split-Path -Parent $PSScriptRoot
$out=Join-Path $root 'build/diagnostics/actor-prompt'
New-Item -ItemType Directory -Force $out | Out-Null
$header=Join-Path $out 'inja.hpp'
$expected='8022ce5a782e911598accc42311ac44a0b9ccd9ad5995f439c828fb534974543'
if(!(Test-Path $header)){Invoke-WebRequest -UseBasicParsing 'https://raw.githubusercontent.com/pantor/inja/v3.4.0/single_include/inja/inja.hpp' -OutFile $header}
if((Get-FileHash $header).Hash.ToLowerInvariant() -ne $expected){throw 'Unexpected Inja test dependency hash'}
$include=Join-Path $root 'build/native-release/vcpkg_installed/x64-windows-static-md/include'
$test=Join-Path $root 'tools/test_actor_prompt.cpp'
$exe=Join-Path $out 'test_actor_prompt.exe'
Push-Location $out
try{
 & cmd.exe /d /s /c "`"E:/Visual Studio/Common7/Tools/VsDevCmd.bat`" -arch=x64 -host_arch=x64 >nul && cl.exe /nologo /std:c++20 /utf-8 /EHsc /DNOMINMAX /I`"$include`" /I`"$out`" `"$test`" /Fe:`"$exe`""
 if($LASTEXITCODE){throw 'Actor template test compilation failed'}
 & $exe (Join-Path $root 'SkyrimNetPrompts/0260_mme_extensions_milkmaid.prompt')
 if($LASTEXITCODE){throw 'Actor template render tests failed'}
 & $exe (Join-Path $root 'SkyrimNetPrompts/0950_mme_extensions_breastfeeding.prompt')
 if($LASTEXITCODE){throw 'Breastfeeding template render tests failed'}
}finally{Pop-Location}
& python -B (Join-Path $root 'tools/test_actor_prompt_contracts.py')
if($LASTEXITCODE){throw 'Actor prompt integration contracts failed'}
