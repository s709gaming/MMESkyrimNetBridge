$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$pluginPath = Join-Path $root 'MMEAlert.esp'
$bytes = [IO.File]::ReadAllBytes($pluginPath)

function Read-U16([byte[]] $data, [int] $offset) {
    [BitConverter]::ToUInt16($data, $offset)
}

function Read-U32([byte[]] $data, [int] $offset) {
    [BitConverter]::ToUInt32($data, $offset)
}

function Write-U32([byte[]] $data, [int] $offset, [uint32] $value) {
    [BitConverter]::GetBytes($value).CopyTo($data, $offset)
}

function New-Subrecord([string] $signature, [byte[]] $payload) {
    $result = New-Object byte[] (6 + $payload.Length)
    [Text.Encoding]::ASCII.GetBytes($signature).CopyTo($result, 0)
    [BitConverter]::GetBytes([uint16] $payload.Length).CopyTo($result, 4)
    $payload.CopyTo($result, 6)
    return ,$result
}

function Join-Bytes([Collections.Generic.List[byte[]]] $parts) {
    $length = ($parts | Measure-Object Length -Sum).Sum
    $result = New-Object byte[] $length
    $offset = 0
    foreach ($part in $parts) {
        $part.CopyTo($result, $offset)
        $offset += $part.Length
    }
    return ,$result
}

function Repair-Record([byte[]] $record, [string] $expectedSignature, [string] $expectedEditorId) {
    $signature = [Text.Encoding]::ASCII.GetString($record, 0, 4)
    if ($signature -ne $expectedSignature) {
        throw "Expected $expectedSignature record, found $signature."
    }

    $dataSize = Read-U32 $record 4
    if ($record.Length -ne 24 + $dataSize) {
        throw "Unexpected $expectedSignature record length."
    }

    $parts = [Collections.Generic.List[byte[]]]::new()
    $editorId = $null
    $offset = 24
    while ($offset -lt $record.Length) {
        $subSignature = [Text.Encoding]::ASCII.GetString($record, $offset, 4)
        $subLength = Read-U16 $record ($offset + 4)
        $totalLength = 6 + $subLength
        if ($offset + $totalLength -gt $record.Length) {
            throw "Malformed $subSignature subrecord in $expectedSignature."
        }

        if ($subSignature -eq 'EDID') {
            $editorId = [Text.Encoding]::ASCII.GetString($record, $offset + 6, $subLength).TrimEnd([char] 0)
        }

        $drop = ($expectedSignature -eq 'MGEF' -and $subSignature -eq 'DNAM') -or
            ($expectedSignature -eq 'SPEL' -and $subSignature -in @('FULL', 'DESC'))

        if (-not $drop) {
            if ($expectedSignature -eq 'SPEL' -and $subSignature -eq 'EFIT') {
                if ($subLength -notin @(8, 12)) {
                    throw "Refusing unexpected EFIT length $subLength."
                }
                $parts.Add((New-Subrecord 'EFIT' (New-Object byte[] 12)))
            } else {
                $copy = New-Object byte[] $totalLength
                [Array]::Copy($record, $offset, $copy, 0, $totalLength)
                $parts.Add($copy)
            }
        }
        $offset += $totalLength
    }

    if ($editorId -ne $expectedEditorId) {
        throw "Expected EditorID $expectedEditorId, found $editorId."
    }

    $body = Join-Bytes $parts
    $result = New-Object byte[] (24 + $body.Length)
    [Array]::Copy($record, 0, $result, 0, 24)
    Write-U32 $result 4 $body.Length
    $body.CopyTo($result, 24)
    return ,$result
}

$headerSize = Read-U32 $bytes 4
$headerEnd = 24 + $headerSize
$output = [Collections.Generic.List[byte[]]]::new()
$header = New-Object byte[] $headerEnd
[Array]::Copy($bytes, 0, $header, 0, $headerEnd)
$output.Add($header)

$foundMgef = $false
$foundSpel = $false
$position = $headerEnd
while ($position -lt $bytes.Length) {
    if ([Text.Encoding]::ASCII.GetString($bytes, $position, 4) -ne 'GRUP') {
        throw "Expected top-level GRUP at offset $position."
    }
    $groupSize = Read-U32 $bytes ($position + 4)
    $label = [Text.Encoding]::ASCII.GetString($bytes, $position + 8, 4)
    $group = New-Object byte[] $groupSize
    [Array]::Copy($bytes, $position, $group, 0, $groupSize)

    if ($label -in @('MGEF', 'SPEL')) {
        $groupParts = [Collections.Generic.List[byte[]]]::new()
        $groupHeader = New-Object byte[] 24
        [Array]::Copy($group, 0, $groupHeader, 0, 24)
        $groupParts.Add($groupHeader)
        $recordOffset = 24
        while ($recordOffset -lt $group.Length) {
            $recordSize = 24 + (Read-U32 $group ($recordOffset + 4))
            $record = New-Object byte[] $recordSize
            [Array]::Copy($group, $recordOffset, $record, 0, $recordSize)
            $localFormId = (Read-U32 $record 12) -band 0x00FFFFFF
            if ($label -eq 'MGEF' -and $localFormId -eq 0x000804) {
                $record = Repair-Record $record 'MGEF' 'MMEAlerts_PlayerMonitorEffect'
                $foundMgef = $true
            } elseif ($label -eq 'SPEL' -and $localFormId -eq 0x000805) {
                $record = Repair-Record $record 'SPEL' 'MMEAlerts_PlayerMonitorAbility'
                $foundSpel = $true
            }
            $groupParts.Add($record)
            $recordOffset += $recordSize
        }
        $group = Join-Bytes $groupParts
        Write-U32 $group 4 $group.Length
    }

    $output.Add($group)
    $position += $groupSize
}

if (-not $foundMgef -or -not $foundSpel) {
    throw 'The expected player-monitor records were not both found; nothing was written.'
}

$repaired = Join-Bytes $output
$temporaryPath = "$pluginPath.repairing"
[IO.File]::WriteAllBytes($temporaryPath, $repaired)
Move-Item -LiteralPath $temporaryPath -Destination $pluginPath -Force
Write-Host "Repaired $pluginPath"
