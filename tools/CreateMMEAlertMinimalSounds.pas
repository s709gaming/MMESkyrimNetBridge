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
  AddSoundFile(PoolHot, 'fx\MMESkyrimNetBridge\Hot Sounds\001.wav');
  AddSoundFile(PoolHot, 'fx\MMESkyrimNetBridge\Hot Sounds\002.wav');
  AddSoundFile(PoolHot, 'fx\MMESkyrimNetBridge\Hot Sounds\003.wav');
  AddSoundFile(PoolHot, 'fx\MMESkyrimNetBridge\Hot Sounds\004.wav');
  AddSoundFile(PoolHot, 'fx\MMESkyrimNetBridge\Hot Sounds\005.wav');
  AddSoundFile(PoolHot, 'fx\MMESkyrimNetBridge\Hot Sounds\006.wav');
  AddSoundFile(PoolHot, 'fx\MMESkyrimNetBridge\Hot Sounds\007.wav');
  AddSoundFile(PoolHot, 'fx\MMESkyrimNetBridge\Hot Sounds\008.wav');
  AddSoundFile(PoolHot, 'fx\MMESkyrimNetBridge\Hot Sounds\009.wav');
  AddSoundFile(PoolHot, 'fx\MMESkyrimNetBridge\Hot Sounds\010.wav');
  AddSoundFile(PoolHot, 'fx\MMESkyrimNetBridge\Hot Sounds\011.wav');
  PoolMedium := MakePool('MMEAlerts_SNDR_Medium', 0);
  AddSoundFile(PoolMedium, 'fx\MMESkyrimNetBridge\Medium Sounds\001.wav');
  AddSoundFile(PoolMedium, 'fx\MMESkyrimNetBridge\Medium Sounds\002.wav');
  AddSoundFile(PoolMedium, 'fx\MMESkyrimNetBridge\Medium Sounds\003.wav');
  AddSoundFile(PoolMedium, 'fx\MMESkyrimNetBridge\Medium Sounds\004.wav');
  AddSoundFile(PoolMedium, 'fx\MMESkyrimNetBridge\Medium Sounds\005.wav');
  AddSoundFile(PoolMedium, 'fx\MMESkyrimNetBridge\Medium Sounds\006.wav');
  AddSoundFile(PoolMedium, 'fx\MMESkyrimNetBridge\Medium Sounds\007.wav');
  AddSoundFile(PoolMedium, 'fx\MMESkyrimNetBridge\Medium Sounds\008.wav');
  AddSoundFile(PoolMedium, 'fx\MMESkyrimNetBridge\Medium Sounds\009.wav');
  AddSoundFile(PoolMedium, 'fx\MMESkyrimNetBridge\Medium Sounds\010.wav');
  AddSoundFile(PoolMedium, 'fx\MMESkyrimNetBridge\Medium Sounds\011.wav');
  AddSoundFile(PoolMedium, 'fx\MMESkyrimNetBridge\Medium Sounds\012.wav');
  AddSoundFile(PoolMedium, 'fx\MMESkyrimNetBridge\Medium Sounds\013.wav');
  AddSoundFile(PoolMedium, 'fx\MMESkyrimNetBridge\Medium Sounds\014.wav');
  AddSoundFile(PoolMedium, 'fx\MMESkyrimNetBridge\Medium Sounds\015.wav');
  AddSoundFile(PoolMedium, 'fx\MMESkyrimNetBridge\Medium Sounds\016.wav');
  AddSoundFile(PoolMedium, 'fx\MMESkyrimNetBridge\Medium Sounds\017.wav');
  AddSoundFile(PoolMedium, 'fx\MMESkyrimNetBridge\Medium Sounds\018.wav');
  AddSoundFile(PoolMedium, 'fx\MMESkyrimNetBridge\Medium Sounds\019.wav');
  AddSoundFile(PoolMedium, 'fx\MMESkyrimNetBridge\Medium Sounds\020.wav');
  AddSoundFile(PoolMedium, 'fx\MMESkyrimNetBridge\Medium Sounds\021.wav');
  AddSoundFile(PoolMedium, 'fx\MMESkyrimNetBridge\Medium Sounds\022.wav');
  AddSoundFile(PoolMedium, 'fx\MMESkyrimNetBridge\Medium Sounds\023.wav');
  AddSoundFile(PoolMedium, 'fx\MMESkyrimNetBridge\Medium Sounds\024.wav');
  AddSoundFile(PoolMedium, 'fx\MMESkyrimNetBridge\Medium Sounds\025.wav');
  AddSoundFile(PoolMedium, 'fx\MMESkyrimNetBridge\Medium Sounds\026.wav');
  AddSoundFile(PoolMedium, 'fx\MMESkyrimNetBridge\Medium Sounds\027.wav');
  AddSoundFile(PoolMedium, 'fx\MMESkyrimNetBridge\Medium Sounds\028.wav');
  AddSoundFile(PoolMedium, 'fx\MMESkyrimNetBridge\Medium Sounds\029.wav');
  AddSoundFile(PoolMedium, 'fx\MMESkyrimNetBridge\Medium Sounds\030.wav');
  AddSoundFile(PoolMedium, 'fx\MMESkyrimNetBridge\Medium Sounds\031.wav');
  AddSoundFile(PoolMedium, 'fx\MMESkyrimNetBridge\Medium Sounds\032.wav');
  AddSoundFile(PoolMedium, 'fx\MMESkyrimNetBridge\Medium Sounds\033.wav');
  AddSoundFile(PoolMedium, 'fx\MMESkyrimNetBridge\Medium Sounds\034.wav');
  AddSoundFile(PoolMedium, 'fx\MMESkyrimNetBridge\Medium Sounds\035.wav');
  AddSoundFile(PoolMedium, 'fx\MMESkyrimNetBridge\Medium Sounds\036.wav');
  AddSoundFile(PoolMedium, 'fx\MMESkyrimNetBridge\Medium Sounds\037.wav');
  AddSoundFile(PoolMedium, 'fx\MMESkyrimNetBridge\Medium Sounds\038.wav');
  AddSoundFile(PoolMedium, 'fx\MMESkyrimNetBridge\Medium Sounds\039.wav');
  AddSoundFile(PoolMedium, 'fx\MMESkyrimNetBridge\Medium Sounds\040.wav');
  AddSoundFile(PoolMedium, 'fx\MMESkyrimNetBridge\Medium Sounds\041.wav');
  AddSoundFile(PoolMedium, 'fx\MMESkyrimNetBridge\Medium Sounds\042.wav');
  AddSoundFile(PoolMedium, 'fx\MMESkyrimNetBridge\Medium Sounds\043.wav');
  AddSoundFile(PoolMedium, 'fx\MMESkyrimNetBridge\Medium Sounds\044.wav');
  AddSoundFile(PoolMedium, 'fx\MMESkyrimNetBridge\Medium Sounds\045.wav');
  AddSoundFile(PoolMedium, 'fx\MMESkyrimNetBridge\Medium Sounds\046.wav');
  AddSoundFile(PoolMedium, 'fx\MMESkyrimNetBridge\Medium Sounds\047.wav');
  AddSoundFile(PoolMedium, 'fx\MMESkyrimNetBridge\Medium Sounds\048.wav');
  AddSoundFile(PoolMedium, 'fx\MMESkyrimNetBridge\Medium Sounds\049.wav');
  AddSoundFile(PoolMedium, 'fx\MMESkyrimNetBridge\Medium Sounds\050.wav');
  AddSoundFile(PoolMedium, 'fx\MMESkyrimNetBridge\Medium Sounds\051.wav');
  AddSoundFile(PoolMedium, 'fx\MMESkyrimNetBridge\Medium Sounds\052.wav');
  AddSoundFile(PoolMedium, 'fx\MMESkyrimNetBridge\Medium Sounds\053.wav');
  AddSoundFile(PoolMedium, 'fx\MMESkyrimNetBridge\Medium Sounds\054.wav');
  AddSoundFile(PoolMedium, 'fx\MMESkyrimNetBridge\Medium Sounds\055.wav');
  PoolMild := MakePool('MMEAlerts_SNDR_Mild', 0);
  AddSoundFile(PoolMild, 'fx\MMESkyrimNetBridge\Mild Sounds\001.wav');
  AddSoundFile(PoolMild, 'fx\MMESkyrimNetBridge\Mild Sounds\002.wav');
  AddSoundFile(PoolMild, 'fx\MMESkyrimNetBridge\Mild Sounds\003.wav');
  AddSoundFile(PoolMild, 'fx\MMESkyrimNetBridge\Mild Sounds\004.wav');
  AddSoundFile(PoolMild, 'fx\MMESkyrimNetBridge\Mild Sounds\005.wav');
  AddSoundFile(PoolMild, 'fx\MMESkyrimNetBridge\Mild Sounds\006.wav');
  AddSoundFile(PoolMild, 'fx\MMESkyrimNetBridge\Mild Sounds\007.wav');
  AddSoundFile(PoolMild, 'fx\MMESkyrimNetBridge\Mild Sounds\008.wav');
  AddSoundFile(PoolMild, 'fx\MMESkyrimNetBridge\Mild Sounds\009.wav');
  AddSoundFile(PoolMild, 'fx\MMESkyrimNetBridge\Mild Sounds\010.wav');
  AddSoundFile(PoolMild, 'fx\MMESkyrimNetBridge\Mild Sounds\011.wav');
  AddSoundFile(PoolMild, 'fx\MMESkyrimNetBridge\Mild Sounds\012.wav');
  AddSoundFile(PoolMild, 'fx\MMESkyrimNetBridge\Mild Sounds\013.wav');
  AddSoundFile(PoolMild, 'fx\MMESkyrimNetBridge\Mild Sounds\014.wav');
  AddSoundFile(PoolMild, 'fx\MMESkyrimNetBridge\Mild Sounds\015.wav');
  AddSoundFile(PoolMild, 'fx\MMESkyrimNetBridge\Mild Sounds\016.wav');
  PoolMaleMild := MakePool('MMEAlerts_SNDR_Male_Mild', $000896);
  AddSoundFile(PoolMaleMild, 'fx\MMESkyrimNetBridge\Male sounds\mild\mild_1.wav');
  AddSoundFile(PoolMaleMild, 'fx\MMESkyrimNetBridge\Male sounds\mild\mild_2.wav');
  AddSoundFile(PoolMaleMild, 'fx\MMESkyrimNetBridge\Male sounds\mild\mild_3.wav');
  AddSoundFile(PoolMaleMild, 'fx\MMESkyrimNetBridge\Male sounds\mild\mild_4.wav');
  AddSoundFile(PoolMaleMild, 'fx\MMESkyrimNetBridge\Male sounds\mild\mild_5.wav');
  AddSoundFile(PoolMaleMild, 'fx\MMESkyrimNetBridge\Male sounds\mild\mild_6.wav');
  AddSoundFile(PoolMaleMild, 'fx\MMESkyrimNetBridge\Male sounds\mild\mild_7.wav');
  AddSoundFile(PoolMaleMild, 'fx\MMESkyrimNetBridge\Male sounds\mild\mild_8.wav');
  PoolMaleMedium := MakePool('MMEAlerts_SNDR_Male_Medium', $000897);
  AddSoundFile(PoolMaleMedium, 'fx\MMESkyrimNetBridge\Male sounds\medium\medium_1.wav');
  AddSoundFile(PoolMaleMedium, 'fx\MMESkyrimNetBridge\Male sounds\medium\medium_2.wav');
  AddSoundFile(PoolMaleMedium, 'fx\MMESkyrimNetBridge\Male sounds\medium\medium_3.wav');
  AddSoundFile(PoolMaleMedium, 'fx\MMESkyrimNetBridge\Male sounds\medium\medium_4.wav');
  AddSoundFile(PoolMaleMedium, 'fx\MMESkyrimNetBridge\Male sounds\medium\medium_5.wav');
  AddSoundFile(PoolMaleMedium, 'fx\MMESkyrimNetBridge\Male sounds\medium\medium_6.wav');
  AddSoundFile(PoolMaleMedium, 'fx\MMESkyrimNetBridge\Male sounds\medium\medium_7.wav');
  AddSoundFile(PoolMaleMedium, 'fx\MMESkyrimNetBridge\Male sounds\medium\medium_8.wav');
  AddSoundFile(PoolMaleMedium, 'fx\MMESkyrimNetBridge\Male sounds\medium\medium_9.wav');
  PoolMaleHot := MakePool('MMEAlerts_SNDR_Male_Hot', $000898);
  AddSoundFile(PoolMaleHot, 'fx\MMESkyrimNetBridge\Male sounds\hot\hot_1.wav');
  AddSoundFile(PoolMaleHot, 'fx\MMESkyrimNetBridge\Male sounds\hot\hot_2.wav');
  AddSoundFile(PoolMaleHot, 'fx\MMESkyrimNetBridge\Male sounds\hot\hot_3.wav');
  AddSoundFile(PoolMaleHot, 'fx\MMESkyrimNetBridge\Male sounds\hot\hot_4.wav');
  AddSoundFile(PoolMaleHot, 'fx\MMESkyrimNetBridge\Male sounds\hot\hot_5.wav');
  AddSoundFile(PoolMaleHot, 'fx\MMESkyrimNetBridge\Male sounds\hot\hot_6.wav');
  AddSoundFile(PoolMaleHot, 'fx\MMESkyrimNetBridge\Male sounds\hot\hot_7.wav');
  AddSoundFile(PoolMaleHot, 'fx\MMESkyrimNetBridge\Male sounds\hot\hot_8.wav');
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
