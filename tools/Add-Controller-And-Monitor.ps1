$ErrorActionPreference = 'Stop'
$root=Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$pluginPath=Join-Path $root 'MMEAlert.esp'
$skyrim='E:\Steam\steamapps\common\Skyrim Special Edition\Data\Skyrim.esm'
$b=[IO.File]::ReadAllBytes($pluginPath)
function U16([byte[]]$x,[int]$o){[BitConverter]::ToUInt16($x,$o)}
function U32([byte[]]$x,[int]$o){[BitConverter]::ToUInt32($x,$o)}
function W32([byte[]]$x,[int]$o,[uint32]$v){[BitConverter]::GetBytes($v).CopyTo($x,$o)}
function Sub([string]$s,[byte[]]$d){$r=New-Object byte[](6+$d.Length);[Text.Encoding]::ASCII.GetBytes($s).CopyTo($r,0);[BitConverter]::GetBytes([uint16]$d.Length).CopyTo($r,4);$d.CopyTo($r,6);$r}
function Join($parts){$n=($parts|Measure-Object Length -Sum).Sum;$r=New-Object byte[] $n;$o=0;foreach($p in $parts){$p.CopyTo($r,$o);$o+=$p.Length};$r}
function Entry([string]$name){$n=[Text.Encoding]::ASCII.GetBytes($name);$r=New-Object byte[](2+$n.Length+3);[BitConverter]::GetBytes([uint16]$n.Length).CopyTo($r,0);$n.CopyTo($r,2);$r}
function Record([string]$sig,[uint32]$fid,[byte[]]$data){$r=New-Object byte[](24+$data.Length);[Text.Encoding]::ASCII.GetBytes($sig).CopyTo($r,0);W32 $r 4 $data.Length;W32 $r 12 $fid;[BitConverter]::GetBytes([uint16]44).CopyTo($r,20);$data.CopyTo($r,24);$r}
function NewGroup([string]$sig,[byte[]]$record){$g=New-Object byte[](24+$record.Length);[Text.Encoding]::ASCII.GetBytes('GRUP').CopyTo($g,0);W32 $g 4 $g.Length;[Text.Encoding]::ASCII.GetBytes($sig).CopyTo($g,8);$record.CopyTo($g,24);$g}

if([Text.Encoding]::ASCII.GetString($b).Contains('MMEAlertsController')){throw 'Controller already attached'}
$hs=U32 $b 4;$p=24+$hs;$groups=[Collections.Generic.List[byte[]]]::new()
while($p-lt$b.Length){$gs=U32 $b ($p+4);$label=[Text.Encoding]::ASCII.GetString($b,$p+8,4);$g=New-Object byte[] $gs;[Array]::Copy($b,$p,$g,0,$gs)
 if($label-eq'QUST'){$r=24;$sz=U32 $g ($r+4);$ds=$r+24;$de=$ds+$sz;$parts=[Collections.Generic.List[byte[]]]::new();$k=$ds
  while($k-lt$de){$s=[Text.Encoding]::ASCII.GetString($g,$k,4);$l=U16 $g ($k+4);if($s-eq'VMAD'){$vm=New-Object byte[] $l;[Array]::Copy($g,$k+6,$vm,0,$l);$count=U16 $vm 4;[BitConverter]::GetBytes([uint16]($count+1)).CopyTo($vm,4);$insert=$vm.Length-7;$e=Entry 'MMEAlertsController';$nv=New-Object byte[]($vm.Length+$e.Length);[Array]::Copy($vm,0,$nv,0,$insert);$e.CopyTo($nv,$insert);[Array]::Copy($vm,$insert,$nv,$insert+$e.Length,7);$parts.Add((Sub 'VMAD' $nv))}else{$c=New-Object byte[](6+$l);[Array]::Copy($g,$k,$c,0,$c.Length);$parts.Add($c)};$k+=6+$l}
  $nd=Join $parts;$nr=New-Object byte[](24+$nd.Length);[Array]::Copy($g,$r,$nr,0,24);W32 $nr 4 $nd.Length;$nd.CopyTo($nr,24);$g=NewGroup 'QUST' $nr
 };$groups.Add($g);$p+=$gs}

$vmParts=[Collections.Generic.List[byte[]]]::new();$vh=New-Object byte[] 6;[BitConverter]::GetBytes([uint16]5).CopyTo($vh,0);[BitConverter]::GetBytes([uint16]2).CopyTo($vh,2);[BitConverter]::GetBytes([uint16]1).CopyTo($vh,4);$vmParts.Add($vh);$vmParts.Add((Entry 'MMEAlertsPlayerEffect'));$vm=Join $vmParts
$mParts=[Collections.Generic.List[byte[]]]::new();$mParts.Add((Sub 'EDID' ([Text.Encoding]::ASCII.GetBytes("MMEAlerts_PlayerMonitorEffect`0"))));$mParts.Add((Sub 'VMAD' $vm));$data=New-Object byte[] 152;$mParts.Add((Sub 'DATA' $data));$mParts.Add((Sub 'SNDD' (New-Object byte[] 0)));$dnam=New-Object byte[] 4;$mParts.Add((Sub 'DNAM' $dnam));$mgef=NewGroup 'MGEF' (Record 'MGEF' 0x01000804 (Join $mParts))

$tmpl=[IO.File]::ReadAllBytes((Join-Path $root 'tools\ability-template.bin'));$sParts=[Collections.Generic.List[byte[]]]::new();$k=0;while($k-lt$tmpl.Length){$s=[Text.Encoding]::ASCII.GetString($tmpl,$k,4);$l=U16 $tmpl ($k+4);if($s-eq'EDID'){$sParts.Add((Sub 'EDID' ([Text.Encoding]::ASCII.GetBytes("MMEAlerts_PlayerMonitorAbility`0"))))}elseif($s-ne'EFID'-and$s-ne'EFIT'){$c=New-Object byte[](6+$l);[Array]::Copy($tmpl,$k,$c,0,$c.Length);$sParts.Add($c)};$k+=6+$l};$efid=New-Object byte[] 4;W32 $efid 0 0x01000804;$efit=New-Object byte[] 8;$sParts.Add((Sub 'EFID' $efid));$sParts.Add((Sub 'EFIT' $efit));$spel=NewGroup 'SPEL' (Record 'SPEL' 0x01000805 (Join $sParts))

$total=24+$hs+(($groups|Measure-Object Length -Sum).Sum)+$mgef.Length+$spel.Length;$out=New-Object byte[] $total;[Array]::Copy($b,0,$out,0,24+$hs);$at=24+$hs;foreach($g in $groups){$g.CopyTo($out,$at);$at+=$g.Length};$mgef.CopyTo($out,$at);$at+=$mgef.Length;$spel.CopyTo($out,$at);W32 $out 34 6;W32 $out 38 0x00000806;[IO.File]::WriteAllBytes($pluginPath,$out)
Write-Host 'Attached controller and added player event monitor ability.'
