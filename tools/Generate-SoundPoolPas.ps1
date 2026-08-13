$ErrorActionPreference = 'Stop'

$projectRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$soundRoot = Join-Path $projectRoot 'assets\sounds'
$outputPath = Join-Path $projectRoot 'tools\CreateMMEAlertMinimalSounds.pas'
$files = Get-ChildItem -LiteralPath $soundRoot -Recurse -File -Filter '*.wav' | Sort-Object FullName
if ($files.Count -eq 0) { throw "No WAV files found below $soundRoot" }

function Q([string]$value) { "'" + $value.Replace("'", "''") + "'" }

$groups = $files | Group-Object { $_.Directory.Name } | Sort-Object Name
$lines = [Collections.Generic.List[string]]::new()
@'
unit UserScript;

var
  TargetFile, SkyrimFile, DescriptorTemplate, MarkerTemplate: IInterface;
  DescriptorCount, MarkerCount, SoundCount, RemovedCount: Integer;

function FindFileByName(aName: string): IInterface;
var i: Integer;
begin
  Result := nil;
  for i := 0 to FileCount - 1 do
    if SameText(GetFileName(FileByIndex(i)), aName) then begin
      Result := FileByIndex(i);
      Exit;
    end;
end;

procedure RemoveOldVoiceRecords;
var g, r: IInterface; i: Integer; id: string;
begin
  g := GroupBySignature(TargetFile, 'SNDR');
  for i := ElementCount(g) - 1 downto 0 do begin
    r := ElementByIndex(g, i);
    id := EditorID(r);
    if (Pos('MMEAlerts_SNDR_Voice', id) = 1) and
       (id <> 'MMEAlerts_SNDR_Mild') and
       (id <> 'MMEAlerts_SNDR_Medium') and
       (id <> 'MMEAlerts_SNDR_Hot') then begin
      Remove(r);
      Inc(RemovedCount);
    end;
  end;

  g := GroupBySignature(TargetFile, 'SOUN');
  if Assigned(g) then
    for i := ElementCount(g) - 1 downto 0 do begin
      r := ElementByIndex(g, i);
      id := EditorID(r);
      if Pos('MMEAlerts_SOUN_Voice', id) = 1 then begin
        Remove(r);
        Inc(RemovedCount);
      end;
    end;
end;

procedure ClearSoundFiles(aRecord: IInterface);
var sounds: IInterface;
begin
  sounds := ElementByPath(aRecord, 'Sounds');
  if not Assigned(sounds) then Exit;
  while ElementCount(sounds) > 0 do Remove(ElementByIndex(sounds, 0));
end;

procedure AddSoundFile(aRecord: IInterface; aPath: string);
var sounds, e: IInterface;
begin
  sounds := ElementByPath(aRecord, 'Sounds');
  e := ElementAssign(sounds, HighInteger, nil, False);
  SetElementEditValues(e, 'ANAM - File Name', aPath);
  Inc(SoundCount);
end;

function MakePool(aEditorID: string): IInterface;
begin
  Result := MainRecordByEditorID(GroupBySignature(TargetFile, 'SNDR'), aEditorID);
  if not Assigned(Result) then begin
    Result := wbCopyElementToFile(DescriptorTemplate, TargetFile, True, True);
    Inc(DescriptorCount);
  end;
  SetEditorID(Result, aEditorID);
  ClearSoundFiles(Result);
end;

procedure MakeMarker(aDescriptor, aMarkerID: string);
var marker: IInterface;
begin
  marker := MainRecordByEditorID(GroupBySignature(TargetFile, 'SOUN'), aMarkerID);
  if not Assigned(marker) then begin
    marker := wbCopyElementToFile(MarkerTemplate, TargetFile, True, True);
    Inc(MarkerCount);
  end;
  SetEditorID(marker, aMarkerID);
  SetElementEditValues(marker, 'SDSC', Name(aDescriptor));
end;

function Initialize: Integer;
var PoolMild, PoolMedium, PoolHot: IInterface;
begin
  Result := 1;
  TargetFile := FindFileByName('MMEAlert.esp');
  SkyrimFile := FindFileByName('Skyrim.esm');
  if not Assigned(TargetFile) or not Assigned(SkyrimFile) then begin
    AddMessage('ERROR: Load Skyrim.esm and MMEAlert.esp.');
    Exit;
  end;
  DescriptorTemplate := RecordByFormID(SkyrimFile, $00000E48, True);
  MarkerTemplate := RecordByFormID(SkyrimFile, $00000E06, True);
  RemoveOldVoiceRecords;
  PoolHot := MakePool('MMEAlerts_SNDR_Hot');
'@ -split "`r?`n" | ForEach-Object { $lines.Add($_) }

foreach ($groupName in @('Hot Sounds','Medium Sounds','Mild Sounds')) {
    $variable = switch ($groupName) { 'Hot Sounds' {'PoolHot'} 'Medium Sounds' {'PoolMedium'} 'Mild Sounds' {'PoolMild'} }
    if ($groupName -eq 'Medium Sounds') { $lines.Add("  PoolMedium := MakePool('MMEAlerts_SNDR_Medium');") }
    if ($groupName -eq 'Mild Sounds') { $lines.Add("  PoolMild := MakePool('MMEAlerts_SNDR_Mild');") }
    $group = $groups | Where-Object Name -eq $groupName
    foreach ($file in $group.Group) {
        $path = 'Data\Sound\fx\MMESkyrimNetBridge\' + $groupName + '\' + $file.Name
        $lines.Add('  AddSoundFile(' + $variable + ', ' + (Q $path) + ');')
    }
}

@'
  MakeMarker(PoolMild, 'MMEAlerts_SOUN_Mild');
  MakeMarker(PoolMedium, 'MMEAlerts_SOUN_Medium');
  MakeMarker(PoolHot, 'MMEAlerts_SOUN_Hot');
  AddMessage('MME Alerts minimal sounds complete.');
  AddMessage('Old records removed: ' + IntToStr(RemovedCount));
  AddMessage('Descriptors created: ' + IntToStr(DescriptorCount));
  AddMessage('Markers created: ' + IntToStr(MarkerCount));
  AddMessage('WAV paths assigned: ' + IntToStr(SoundCount));
  Result := 0;
end;

end.
'@ -split "`r?`n" | ForEach-Object { $lines.Add($_) }

$lines | Set-Content -LiteralPath $outputPath -Encoding UTF8
Write-Host "Generated $outputPath with $($files.Count) WAV paths."
