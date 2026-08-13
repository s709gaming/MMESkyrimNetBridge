$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$gameData = "E:\Steam\steamapps\common\Skyrim Special Edition\Data"
$pluginPath = Join-Path $projectRoot "MMEAlert.esp"
$skyrimPath = Join-Path $gameData "Skyrim.esm"

$sourceMild = Join-Path $projectRoot "assets\Data\Sound\fx\MMESkyrimNetBridge\VoiceSlot 01 (Female)\Mild Sounds\001.wav"
$sourceHot = Join-Path $projectRoot "assets\Data\Sound\fx\MMESkyrimNetBridge\VoiceSlot 01 (Female)\Hot Sounds\001.wav"
$capacityRelative = "Data\Sound\fx\MMESkyrimNetBridge\Capacity50\MMEBridge_Capacity50_01.wav"
$leakingRelative = "Data\Sound\fx\MMESkyrimNetBridge\Leaking\MMEBridge_Leaking_01.wav"
$capacityFile = Join-Path (Join-Path $projectRoot "assets") $capacityRelative
$leakingFile = Join-Path (Join-Path $projectRoot "assets") $leakingRelative

foreach ($required in @($pluginPath, $skyrimPath, $sourceMild, $sourceHot)) {
    if (!(Test-Path -LiteralPath $required)) {
        throw "Required file not found: $required"
    }
}

New-Item -ItemType Directory -Force -Path (Split-Path $capacityFile), (Split-Path $leakingFile) | Out-Null
Copy-Item -LiteralPath $sourceMild -Destination $capacityFile -Force
Copy-Item -LiteralPath $sourceHot -Destination $leakingFile -Force

function Read-UInt32([byte[]] $bytes, [int] $offset) {
    return [BitConverter]::ToUInt32($bytes, $offset)
}

function Write-UInt32([byte[]] $bytes, [int] $offset, [uint32] $value) {
    [BitConverter]::GetBytes($value).CopyTo($bytes, $offset)
}

function Find-VanillaTemplate {
    param([string] $Path, [uint32] $WantedFormId)

    $stream = [IO.File]::OpenRead($Path)
    try {
        # Skyrim.esm's SNDR top-level group begins here in the supported local runtime.
        $stream.Seek(249105535, [IO.SeekOrigin]::Begin) | Out-Null
        $header = New-Object byte[] 24
        while ($stream.Read($header, 0, 24) -eq 24) {
            if ([Text.Encoding]::ASCII.GetString($header, 0, 4) -ne "SNDR") {
                break
            }
            $size = Read-UInt32 $header 4
            $formId = Read-UInt32 $header 12
            $data = New-Object byte[] $size
            if ($stream.Read($data, 0, $size) -ne $size) {
                throw "Unexpected end of Skyrim.esm while reading SNDR records."
            }
            if ($formId -eq $WantedFormId) {
                return [pscustomobject]@{ Header = $header; Data = $data }
            }
        }
    }
    finally {
        $stream.Dispose()
    }
    throw ("Vanilla SNDR template {0:X8} was not found." -f $WantedFormId)
}

function New-Subrecord([string] $Signature, [byte[]] $Data) {
    $result = New-Object byte[] (6 + $Data.Length)
    [Text.Encoding]::ASCII.GetBytes($Signature).CopyTo($result, 0)
    [BitConverter]::GetBytes([uint16]$Data.Length).CopyTo($result, 4)
    $Data.CopyTo($result, 6)
    return $result
}

function New-SoundRecord {
    param(
        [pscustomobject] $Template,
        [uint32] $FormId,
        [string] $EditorId,
        [string] $SoundPath
    )

    $parts = [Collections.Generic.List[byte[]]]::new()
    $offset = 0
    $insertedSound = $false
    while ($offset -lt $Template.Data.Length) {
        $signature = [Text.Encoding]::ASCII.GetString($Template.Data, $offset, 4)
        $length = [BitConverter]::ToUInt16($Template.Data, $offset + 4)
        $payload = New-Object byte[] $length
        [Array]::Copy($Template.Data, $offset + 6, $payload, 0, $length)

        if ($signature -eq "EDID") {
            $parts.Add((New-Subrecord "EDID" ([Text.Encoding]::ASCII.GetBytes($EditorId + [char]0))))
        }
        elseif ($signature -eq "ANAM") {
            if (!$insertedSound) {
                $parts.Add((New-Subrecord "ANAM" ([Text.Encoding]::ASCII.GetBytes($SoundPath + [char]0))))
                $insertedSound = $true
            }
        }
        else {
            $parts.Add((New-Subrecord $signature $payload))
        }
        $offset += 6 + $length
    }

    $dataLength = ($parts | Measure-Object -Property Length -Sum).Sum
    $record = New-Object byte[] (24 + $dataLength)
    [Array]::Copy($Template.Header, 0, $record, 0, 24)
    Write-UInt32 $record 4 ([uint32]$dataLength)
    Write-UInt32 $record 8 0
    Write-UInt32 $record 12 $FormId

    $writeAt = 24
    foreach ($part in $parts) {
        $part.CopyTo($record, $writeAt)
        $writeAt += $part.Length
    }
    return $record
}

$template = Find-VanillaTemplate -Path $skyrimPath -WantedFormId 0x00000E48
$capacityRecord = New-SoundRecord -Template $template -FormId 0x01000801 -EditorId "MMEBridge_SNDR_Capacity50" -SoundPath $capacityRelative
$leakingRecord = New-SoundRecord -Template $template -FormId 0x01000802 -EditorId "MMEBridge_SNDR_Leaking" -SoundPath $leakingRelative

$groupSize = 24 + $capacityRecord.Length + $leakingRecord.Length
$group = New-Object byte[] $groupSize
[Text.Encoding]::ASCII.GetBytes("GRUP").CopyTo($group, 0)
Write-UInt32 $group 4 ([uint32]$groupSize)
[Text.Encoding]::ASCII.GetBytes("SNDR").CopyTo($group, 8)
Write-UInt32 $group 12 0
[BitConverter]::GetBytes([uint16]0).CopyTo($group, 16)
[BitConverter]::GetBytes([uint16]0).CopyTo($group, 18)
Write-UInt32 $group 20 0
$capacityRecord.CopyTo($group, 24)
$leakingRecord.CopyTo($group, 24 + $capacityRecord.Length)

$plugin = [IO.File]::ReadAllBytes($pluginPath)
if ([Text.Encoding]::ASCII.GetString($plugin, 0, 4) -ne "TES4") {
    throw "MMEAlert.esp does not have a valid TES4 header."
}
if ([Text.Encoding]::ASCII.GetString($plugin, $plugin.Length - 24, 4) -eq "GRUP" -and
    [Text.Encoding]::ASCII.GetString($plugin, $plugin.Length - 16, 4) -eq "SNDR") {
    throw "MMEAlert.esp already contains an SNDR group; refusing to append a duplicate test group."
}

# HEDR payload: version (4), record count (4), next object ID (4).
$hedrOffset = 24
if ([Text.Encoding]::ASCII.GetString($plugin, $hedrOffset, 4) -ne "HEDR") {
    throw "MMEAlert.esp has an unexpected TES4 header layout."
}
$recordCount = Read-UInt32 $plugin ($hedrOffset + 10)
Write-UInt32 $plugin ($hedrOffset + 10) ([uint32]($recordCount + 2))
Write-UInt32 $plugin ($hedrOffset + 14) 0x00000803

$output = New-Object byte[] ($plugin.Length + $group.Length)
$plugin.CopyTo($output, 0)
$group.CopyTo($output, $plugin.Length)
[IO.File]::WriteAllBytes($pluginPath, $output)

Write-Host "Added MMEBridge_SNDR_Capacity50 [00000801]"
Write-Host "Added MMEBridge_SNDR_Leaking [00000802]"
Write-Host "Copied two test WAV files into assets\Data\Sound\fx\MMESkyrimNetBridge"
