$ErrorActionPreference = "Stop"
$pluginPath = Join-Path (Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)) "MMEAlert.esp"
$b = [IO.File]::ReadAllBytes($pluginPath)

function U16([byte[]]$x,[int]$o){[BitConverter]::ToUInt16($x,$o)}
function U32([byte[]]$x,[int]$o){[BitConverter]::ToUInt32($x,$o)}
function W32([byte[]]$x,[int]$o,[uint32]$v){[BitConverter]::GetBytes($v).CopyTo($x,$o)}
function Sub([string]$s,[byte[]]$d){$r=New-Object byte[](6+$d.Length);[Text.Encoding]::ASCII.GetBytes($s).CopyTo($r,0);[BitConverter]::GetBytes([uint16]$d.Length).CopyTo($r,4);$d.CopyTo($r,6);$r}

if([Text.Encoding]::ASCII.GetString($b,0,4)-ne'TES4'){throw 'Invalid plugin'}
$headerSize=U32 $b 4
$headerEnd=24+$headerSize
$headerParts=[Collections.Generic.List[byte[]]]::new()
$o=24
while($o-lt$headerEnd){
  $sig=[Text.Encoding]::ASCII.GetString($b,$o,4);$len=U16 $b ($o+4)
  $chunk=New-Object byte[](6+$len);[Array]::Copy($b,$o,$chunk,0,$chunk.Length)
  if($sig-ne'MAST' -or [Text.Encoding]::ASCII.GetString($b,$o+6,$len).Trim([char]0)-ne'MilkModNEW.esp'){$headerParts.Add($chunk)}
  else{$o+=6+$len;if([Text.Encoding]::ASCII.GetString($b,$o,4)-eq'DATA'){$o+=6+(U16 $b ($o+4))};continue}
  $o+=6+$len
}

$groups=[Collections.Generic.List[byte[]]]::new()
$p=$headerEnd
while($p-lt$b.Length){
  $gs=U32 $b ($p+4);$originalGs=$gs;$label=[Text.Encoding]::ASCII.GetString($b,$p+8,4)
  if($label-in @('QUST','SNDR')){
    $g=New-Object byte[] $gs;[Array]::Copy($b,$p,$g,0,$gs)
    $r=24
    while($r-lt$gs){
      $fid=U32 $g ($r+12);$local=$fid-band 0xFFFFFF
      W32 $g ($r+12) ([uint32](0x01000000-bor$local))
      if($label-eq'QUST'){
        $size=U32 $g ($r+4);$dstart=$r+24;$dend=$dstart+$size;$k=$dstart
        $parts=[Collections.Generic.List[byte[]]]::new()
        while($k-lt$dend){
          $sig=[Text.Encoding]::ASCII.GetString($g,$k,4);$len=U16 $g ($k+4)
          if($sig-eq'VMAD'){
            $vm=New-Object byte[] $len;[Array]::Copy($g,$k+6,$vm,0,$len)
            [BitConverter]::GetBytes([uint16]2).CopyTo($vm,4)
            $entryName=[Text.Encoding]::ASCII.GetBytes('MMEAlertsMCM')
            $entry=New-Object byte[](2+$entryName.Length+3)
            [BitConverter]::GetBytes([uint16]$entryName.Length).CopyTo($entry,0);$entryName.CopyTo($entry,2)
            # Existing quest VMAD has a seven-byte fragment tail after its script entry.
            $insertAt=$vm.Length-7;$newVm=New-Object byte[]($vm.Length+$entry.Length)
            [Array]::Copy($vm,0,$newVm,0,$insertAt);$entry.CopyTo($newVm,$insertAt);[Array]::Copy($vm,$insertAt,$newVm,$insertAt+$entry.Length,7)
            $parts.Add((Sub 'VMAD' $newVm))
          } else {$chunk=New-Object byte[](6+$len);[Array]::Copy($g,$k,$chunk,0,$chunk.Length);$parts.Add($chunk)}
          $k+=6+$len
        }
        $newSize=($parts|Measure-Object Length -Sum).Sum;$record=New-Object byte[] (24+$newSize);[Array]::Copy($g,$r,$record,0,24);W32 $record 4 ([uint32]$newSize);$q=24;foreach($part in $parts){$part.CopyTo($record,$q);$q+=$part.Length}
        $newGroup=New-Object byte[] (24+$record.Length);[Array]::Copy($g,0,$newGroup,0,24);W32 $newGroup 4 ([uint32]$newGroup.Length);$record.CopyTo($newGroup,24);$g=$newGroup;$gs=$g.Length
      }
      $r+=24+(U32 $g ($r+4))
    }
    $groups.Add($g)
  }
  $p+=$originalGs
}

$newHeaderSize=($headerParts|Measure-Object Length -Sum).Sum
$total=24+$newHeaderSize+(($groups|Measure-Object Length -Sum).Sum)
$out=New-Object byte[] $total;[Array]::Copy($b,0,$out,0,24);W32 $out 4 ([uint32]$newHeaderSize)
$at=24;foreach($part in $headerParts){$part.CopyTo($out,$at);$at+=$part.Length};foreach($g in $groups){$g.CopyTo($out,$at);$at+=$g.Length}
W32 $out 34 4;W32 $out 38 0x00000803
[IO.File]::WriteAllBytes($pluginPath,$out)
Write-Host 'Removed leak records/master and attached MMEAlertsMCM to the controller quest.'
