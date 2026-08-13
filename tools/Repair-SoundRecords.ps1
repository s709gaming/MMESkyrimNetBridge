$ErrorActionPreference = 'Stop'
$pluginPath = Join-Path (Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)) 'MMEAlert.esp'
$bytes = [IO.File]::ReadAllBytes($pluginPath)

function U16([byte[]]$data, [int]$offset) { [BitConverter]::ToUInt16($data, $offset) }
function U32([byte[]]$data, [int]$offset) { [BitConverter]::ToUInt32($data, $offset) }
function W32([byte[]]$data, [int]$offset, [uint32]$value) { [BitConverter]::GetBytes($value).CopyTo($data, $offset) }
function Join-Bytes($parts) {
    $size = ($parts | Measure-Object Length -Sum).Sum
    $result = New-Object byte[] $size
    $at = 0
    foreach ($part in $parts) { $part.CopyTo($result, $at); $at += $part.Length }
    $result
}
function Subrecord([string]$signature, [byte[]]$payload) {
    $result = New-Object byte[] (6 + $payload.Length)
    [Text.Encoding]::ASCII.GetBytes($signature).CopyTo($result, 0)
    [BitConverter]::GetBytes([uint16]$payload.Length).CopyTo($result, 4)
    $payload.CopyTo($result, 6)
    $result
}
function Repair-Record([byte[]]$record) {
    $formId = U32 $record 12
    if ($formId -eq 0x01000801) {
        $soundPath = 'fx\MMESkyrimNetBridge\Capacity50\MMEBridge_Capacity50_01.wav'
    } elseif ($formId -eq 0x01000802) {
        $soundPath = 'fx\MMESkyrimNetBridge\Leaking\MMEBridge_Leaking_01.wav'
    } else {
        return $record
    }

    $parts = [Collections.Generic.List[byte[]]]::new()
    $cursor = 24
    while ($cursor -lt $record.Length) {
        $signature = [Text.Encoding]::ASCII.GetString($record, $cursor, 4)
        $length = U16 $record ($cursor + 4)
        if ($signature -eq 'ANAM') {
            $payload = [Text.Encoding]::ASCII.GetBytes($soundPath + [char]0)
            $parts.Add((Subrecord 'ANAM' $payload))
        } else {
            $copy = New-Object byte[] (6 + $length)
            [Array]::Copy($record, $cursor, $copy, 0, $copy.Length)
            $parts.Add($copy)
        }
        $cursor += 6 + $length
    }

    $data = Join-Bytes $parts
    $fixed = New-Object byte[] (24 + $data.Length)
    [Array]::Copy($record, 0, $fixed, 0, 24)
    W32 $fixed 4 $data.Length
    $data.CopyTo($fixed, 24)
    $fixed
}

$headerSize = U32 $bytes 4
$prefixLength = 24 + $headerSize
$groups = [Collections.Generic.List[byte[]]]::new()
$position = $prefixLength
while ($position -lt $bytes.Length) {
    $groupSize = U32 $bytes ($position + 4)
    $label = [Text.Encoding]::ASCII.GetString($bytes, $position + 8, 4)
    if ($label -eq 'SNDR') {
        $records = [Collections.Generic.List[byte[]]]::new()
        $cursor = $position + 24
        while ($cursor -lt $position + $groupSize) {
            $recordSize = 24 + (U32 $bytes ($cursor + 4))
            $record = New-Object byte[] $recordSize
            [Array]::Copy($bytes, $cursor, $record, 0, $recordSize)
            $records.Add((Repair-Record $record))
            $cursor += $recordSize
        }
        $recordBytes = Join-Bytes $records
        $group = New-Object byte[] (24 + $recordBytes.Length)
        [Array]::Copy($bytes, $position, $group, 0, 24)
        W32 $group 4 $group.Length
        $recordBytes.CopyTo($group, 24)
        $groups.Add($group)
    } else {
        $group = New-Object byte[] $groupSize
        [Array]::Copy($bytes, $position, $group, 0, $groupSize)
        $groups.Add($group)
    }
    $position += $groupSize
}

$body = Join-Bytes $groups
$output = New-Object byte[] ($prefixLength + $body.Length)
[Array]::Copy($bytes, 0, $output, 0, $prefixLength)
$body.CopyTo($output, $prefixLength)
# QUST + two SNDR + MGEF + SPEL = five records. The stale value of six
# could make strict loaders distrust the file even though Skyrim loads its quest.
W32 $output 34 5
[IO.File]::WriteAllBytes($pluginPath, $output)
Write-Host 'Rebuilt both SNDR ANAM paths with valid lengths.'
