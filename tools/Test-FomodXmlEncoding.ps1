param([string]$ArchivePath)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot

# Reproduce Nexus-Mods/fomod-installer XmlScriptType.StringStream: the input is
# rewritten as UTF-16BE, but only double-quoted encoding declarations are removed.
# A single-quoted UTF-8 declaration then produces Xml_InvalidCharacter at 1:39.
if (!('MMEFomodEncodingRegression' -as [type])) {
    Add-Type -ReferencedAssemblies System.Xml,System -TypeDefinition @"
using System;
using System.IO;
using System.Text;
using System.Text.RegularExpressions;
using System.Xml;
public static class MMEFomodEncodingRegression {
 public static void Validate(string input) {
  input = Regex.Replace(input, "^([^>]*)encoding=\"[^\"]+\"", "`$1");
  using (var stream = new MemoryStream()) {
   var writer = new StreamWriter(stream, new UnicodeEncoding(true, true));
   writer.Write(input); writer.Flush(); stream.Position = 0;
   using (var reader = XmlReader.Create(stream)) { while (reader.Read()) {} }
  }
 }
}
"@
}

# Negative control ensures this check actually catches the reported regression.
$rejected = $false
try {
    [MMEFomodEncodingRegression]::Validate("<?xml version='1.0' encoding='UTF-8'?>`r`n<config />")
} catch {
    $inner = $_.Exception
    while ($inner.InnerException) { $inner = $inner.InnerException }
    $rejected = $inner -is [System.Xml.XmlException] -and $inner.LineNumber -eq 1 -and $inner.LinePosition -eq 39
}
if (!$rejected) { throw 'Vortex encoding regression negative control did not fail at position 39' }
Write-Host 'PASS: negative control reproduces the Vortex declaration failure at 1:39'

function Assert-InstallerXml([string]$Name, [string]$Text) {
    # Header-free UTF-8 is the canonical cross-installer format, including metadata.
    if ($Text -match '^\s*<\?xml') { throw "XML declaration was reintroduced: $Name" }
    if ($Text.Contains([char]0)) { throw "NUL character in $Name" }
    [xml]$parsed = $Text
    [MMEFomodEncodingRegression]::Validate($Text)
    Write-Host "PASS: normal .NET and Vortex-transformed XML parsing: $Name"
}

if ($ArchivePath) {
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $archive = [IO.Compression.ZipFile]::OpenRead((Resolve-Path -LiteralPath $ArchivePath).Path)
    try {
        foreach ($relative in @('fomod/ModuleConfig.xml','fomod/info.xml')) {
            $entries = @($archive.Entries | Where-Object { $_.FullName.Replace('\','/') -ieq $relative })
            if ($entries.Count -ne 1) { throw "Expected one $relative in archive" }
            $reader = New-Object IO.StreamReader($entries[0].Open(), [Text.Encoding]::UTF8, $true)
            try { $text = $reader.ReadToEnd() } finally { $reader.Dispose() }
            Assert-InstallerXml "$ArchivePath : $relative" $text
        }
    } finally { $archive.Dispose() }
} else {
    foreach ($relative in @('fomod/ModuleConfig.xml','fomod/info.xml')) {
        Assert-InstallerXml $relative ([IO.File]::ReadAllText((Join-Path $projectRoot $relative)))
    }
}
