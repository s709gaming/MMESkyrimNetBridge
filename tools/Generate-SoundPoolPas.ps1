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

function LocalFormID(aRecord: IInterface): Cardinal;
begin
  { FixedFormID is relative to this plugin's master list; mask to the object ID. }
  Result := FixedFormID(aRecord) and $00FFFFFF;
end;

function FindRecordByLocalFormID(aLocalFormID: Cardinal): IInterface;
var fileFormID: Cardinal;
begin
  { RecordByFormID expects an ID in the target file's master-index space. }
  fileFormID := (MasterCount(TargetFile) shl 24) or aLocalFormID;
  Result := RecordByFormID(TargetFile, fileFormID, False);
end;

procedure AssignLocalFormID(aRecord: IInterface; aLocalFormID: Cardinal);
var occupant: IInterface; loadOrderPrefix: Cardinal;
begin
  if LocalFormID(aRecord) = aLocalFormID then Exit;
  occupant := FindRecordByLocalFormID(aLocalFormID);
  if Assigned(occupant) then
    raise Exception.Create('FormID ' + IntToHex(aLocalFormID, 6) +
      ' is already occupied by ' + EditorID(occupant) + '.');
  loadOrderPrefix := GetLoadOrderFormID(aRecord) and $FF000000;
  SetLoadOrderFormID(aRecord, loadOrderPrefix or aLocalFormID);
end;

procedure ValidateLocalFormID(aEditorID: string; aLocalFormID: Cardinal);
var occupant: IInterface;
begin
  occupant := FindRecordByLocalFormID(aLocalFormID);
  if Assigned(occupant) and (EditorID(occupant) <> aEditorID) then
    raise Exception.Create('Required FormID ' + IntToHex(aLocalFormID, 6) +
      ' is occupied by ' + EditorID(occupant) + '; expected ' + aEditorID + '.');
end;

function MakePool(aEditorID: string; aLocalFormID: Cardinal): IInterface;
begin
  Result := MainRecordByEditorID(GroupBySignature(TargetFile, 'SNDR'), aEditorID);
  if not Assigned(Result) then begin
    Result := wbCopyElementToFile(DescriptorTemplate, TargetFile, True, True);
    Inc(DescriptorCount);
  end;
  SetEditorID(Result, aEditorID);
  if aLocalFormID <> 0 then AssignLocalFormID(Result, aLocalFormID);
  ClearSoundFiles(Result);
end;

procedure MakeMarker(aDescriptor: IInterface; aMarkerID: string; aLocalFormID: Cardinal);
var marker: IInterface;
begin
  marker := MainRecordByEditorID(GroupBySignature(TargetFile, 'SOUN'), aMarkerID);
  if not Assigned(marker) then begin
    marker := wbCopyElementToFile(MarkerTemplate, TargetFile, True, True);
    Inc(MarkerCount);
  end;
  SetEditorID(marker, aMarkerID);
  if aLocalFormID <> 0 then AssignLocalFormID(marker, aLocalFormID);
  SetElementEditValues(marker, 'SDSC', Name(aDescriptor));
end;

function Initialize: Integer;
var PoolMild, PoolMedium, PoolHot, PoolMaleMild, PoolMaleMedium,
  PoolMaleHot: IInterface;
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
  ValidateLocalFormID('MMEAlerts_SNDR_Male_Mild', $000896);
  ValidateLocalFormID('MMEAlerts_SNDR_Male_Medium', $000897);
  ValidateLocalFormID('MMEAlerts_SNDR_Male_Hot', $000898);
  ValidateLocalFormID('MMEAlerts_SOUN_Male_Mild', $000899);
  ValidateLocalFormID('MMEAlerts_SOUN_Male_Medium', $00089A);
  ValidateLocalFormID('MMEAlerts_SOUN_Male_Hot', $00089B);
  RemoveOldVoiceRecords;
  PoolHot := MakePool('MMEAlerts_SNDR_Hot', 0);
'@ -split "`r?`n" | ForEach-Object { $lines.Add($_) }

foreach ($groupName in @('Hot Sounds','Medium Sounds','Mild Sounds')) {
    $variable = switch ($groupName) { 'Hot Sounds' {'PoolHot'} 'Medium Sounds' {'PoolMedium'} 'Mild Sounds' {'PoolMild'} }
    if ($groupName -eq 'Medium Sounds') { $lines.Add("  PoolMedium := MakePool('MMEAlerts_SNDR_Medium', 0);") }
    if ($groupName -eq 'Mild Sounds') { $lines.Add("  PoolMild := MakePool('MMEAlerts_SNDR_Mild', 0);") }
    $group = $groups | Where-Object Name -eq $groupName
    foreach ($file in $group.Group) {
        $path = 'fx\MMESkyrimNetBridge\' + $groupName + '\' + $file.Name
        $lines.Add('  AddSoundFile(' + $variable + ', ' + (Q $path) + ');')
    }
}

$maleGroups = @(
    @{ Folder = 'mild'; Variable = 'PoolMaleMild'; EditorID = 'MMEAlerts_SNDR_Male_Mild'; FormID = '$000896' },
    @{ Folder = 'medium'; Variable = 'PoolMaleMedium'; EditorID = 'MMEAlerts_SNDR_Male_Medium'; FormID = '$000897' },
    @{ Folder = 'hot'; Variable = 'PoolMaleHot'; EditorID = 'MMEAlerts_SNDR_Male_Hot'; FormID = '$000898' }
)
foreach ($maleGroup in $maleGroups) {
    $lines.Add("  $($maleGroup.Variable) := MakePool('$($maleGroup.EditorID)', $($maleGroup.FormID));")
    $folderPath = Join-Path (Join-Path $soundRoot 'Male sounds') $maleGroup.Folder
    $groupFiles = Get-ChildItem -LiteralPath $folderPath -File -Filter '*.wav' | Sort-Object Name
    if ($groupFiles.Count -eq 0) { throw "No male $($maleGroup.Folder) WAV files found below $folderPath" }
    foreach ($file in $groupFiles) {
        $path = 'fx\MMESkyrimNetBridge\Male sounds\' + $maleGroup.Folder + '\' + $file.Name
        $lines.Add('  AddSoundFile(' + $maleGroup.Variable + ', ' + (Q $path) + ');')
    }
}

@'
  MakeMarker(PoolMild, 'MMEAlerts_SOUN_Mild', 0);
  MakeMarker(PoolMedium, 'MMEAlerts_SOUN_Medium', 0);
  MakeMarker(PoolHot, 'MMEAlerts_SOUN_Hot', 0);
  MakeMarker(PoolMaleMild, 'MMEAlerts_SOUN_Male_Mild', $000899);
  MakeMarker(PoolMaleMedium, 'MMEAlerts_SOUN_Male_Medium', $00089A);
  MakeMarker(PoolMaleHot, 'MMEAlerts_SOUN_Male_Hot', $00089B);
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
