$ErrorActionPreference = "Stop"

# One-time project-record migration: attach the property-free MMEThoughts script
# to the existing startup quest so it can own OnUpdateGameTime registrations.
$projectRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$pluginPath = Join-Path $projectRoot "MMEAlert.esp"
$scriptName = "MMEThoughts"
$bytes = [IO.File]::ReadAllBytes($pluginPath)

function Read-U16([byte[]]$data, [int]$offset) { [BitConverter]::ToUInt16($data, $offset) }
function Read-U32([byte[]]$data, [int]$offset) { [BitConverter]::ToUInt32($data, $offset) }
function Write-U32([byte[]]$data, [int]$offset, [uint32]$value) { [BitConverter]::GetBytes($value).CopyTo($data, $offset) }
function New-Subrecord([string]$signature, [byte[]]$data) {
    $result = New-Object byte[] (6 + $data.Length)
    [Text.Encoding]::ASCII.GetBytes($signature).CopyTo($result, 0)
    [BitConverter]::GetBytes([uint16]$data.Length).CopyTo($result, 4)
    $data.CopyTo($result, 6)
    $result
}
function Join-Bytes($parts) {
    $length = ($parts | Measure-Object Length -Sum).Sum
    $result = New-Object byte[] $length
    $offset = 0
    foreach ($part in $parts) {
        $part.CopyTo($result, $offset)
        $offset += $part.Length
    }
    $result
}
function New-ScriptEntry([string]$name) {
    $nameBytes = [Text.Encoding]::ASCII.GetBytes($name)
    $result = New-Object byte[] (2 + $nameBytes.Length + 3)
    [BitConverter]::GetBytes([uint16]$nameBytes.Length).CopyTo($result, 0)
    $nameBytes.CopyTo($result, 2)
    $result
}

if ([Text.Encoding]::ASCII.GetString($bytes).Contains($scriptName)) {
    Write-Host "$scriptName is already attached."
    exit 0
}

$headerSize = Read-U32 $bytes 4
$position = 24 + $headerSize
$groups = [Collections.Generic.List[byte[]]]::new()
$attached = $false

while ($position -lt $bytes.Length) {
    $groupSize = Read-U32 $bytes ($position + 4)
    $label = [Text.Encoding]::ASCII.GetString($bytes, $position + 8, 4)
    $group = New-Object byte[] $groupSize
    [Array]::Copy($bytes, $position, $group, 0, $groupSize)

    if ($label -eq "QUST") {
        $recordOffset = 24
        $recordSize = Read-U32 $group ($recordOffset + 4)
        $dataStart = $recordOffset + 24
        $dataEnd = $dataStart + $recordSize
        $parts = [Collections.Generic.List[byte[]]]::new()
        $cursor = $dataStart

        while ($cursor -lt $dataEnd) {
            $signature = [Text.Encoding]::ASCII.GetString($group, $cursor, 4)
            $length = Read-U16 $group ($cursor + 4)
            if ($signature -eq "VMAD") {
                $vmad = New-Object byte[] $length
                [Array]::Copy($group, $cursor + 6, $vmad, 0, $length)
                $count = Read-U16 $vmad 4
                [BitConverter]::GetBytes([uint16]($count + 1)).CopyTo($vmad, 4)
                # Quest VMAD ends with the seven-byte fragment header. Script
                # entries precede it, so insert the new zero-property entry here.
                $insertAt = $vmad.Length - 7
                $entry = New-ScriptEntry $scriptName
                $newVmad = New-Object byte[] ($vmad.Length + $entry.Length)
                [Array]::Copy($vmad, 0, $newVmad, 0, $insertAt)
                $entry.CopyTo($newVmad, $insertAt)
                [Array]::Copy($vmad, $insertAt, $newVmad, $insertAt + $entry.Length, 7)
                $parts.Add((New-Subrecord "VMAD" $newVmad))
                $attached = $true
            } else {
                $subrecord = New-Object byte[] (6 + $length)
                [Array]::Copy($group, $cursor, $subrecord, 0, $subrecord.Length)
                $parts.Add($subrecord)
            }
            $cursor += 6 + $length
        }

        $newData = Join-Bytes $parts
        $newRecord = New-Object byte[] (24 + $newData.Length)
        [Array]::Copy($group, $recordOffset, $newRecord, 0, 24)
        Write-U32 $newRecord 4 $newData.Length
        $newData.CopyTo($newRecord, 24)

        $newGroup = New-Object byte[] (24 + $newRecord.Length)
        [Array]::Copy($group, 0, $newGroup, 0, 24)
        Write-U32 $newGroup 4 $newGroup.Length
        $newRecord.CopyTo($newGroup, 24)
        $group = $newGroup
    }

    $groups.Add($group)
    $position += $groupSize
}

if (!$attached) {
    throw "No quest VMAD was found in MMEAlert.esp."
}

$outputLength = 24 + $headerSize + ($groups | Measure-Object Length -Sum).Sum
$output = New-Object byte[] $outputLength
[Array]::Copy($bytes, 0, $output, 0, 24 + $headerSize)
$outputOffset = 24 + $headerSize
foreach ($group in $groups) {
    $group.CopyTo($output, $outputOffset)
    $outputOffset += $group.Length
}
[IO.File]::WriteAllBytes($pluginPath, $output)
Write-Host "Attached $scriptName to the startup quest."
