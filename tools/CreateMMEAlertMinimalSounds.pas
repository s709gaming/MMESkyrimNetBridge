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
  AddSoundFile(PoolHot, 'Data\Sound\fx\MMESkyrimNetBridge\Hot Sounds\001.wav');
  AddSoundFile(PoolHot, 'Data\Sound\fx\MMESkyrimNetBridge\Hot Sounds\002.wav');
  AddSoundFile(PoolHot, 'Data\Sound\fx\MMESkyrimNetBridge\Hot Sounds\003.wav');
  AddSoundFile(PoolHot, 'Data\Sound\fx\MMESkyrimNetBridge\Hot Sounds\004.wav');
  AddSoundFile(PoolHot, 'Data\Sound\fx\MMESkyrimNetBridge\Hot Sounds\005.wav');
  AddSoundFile(PoolHot, 'Data\Sound\fx\MMESkyrimNetBridge\Hot Sounds\006.wav');
  AddSoundFile(PoolHot, 'Data\Sound\fx\MMESkyrimNetBridge\Hot Sounds\007.wav');
  AddSoundFile(PoolHot, 'Data\Sound\fx\MMESkyrimNetBridge\Hot Sounds\008.wav');
  AddSoundFile(PoolHot, 'Data\Sound\fx\MMESkyrimNetBridge\Hot Sounds\009.wav');
  AddSoundFile(PoolHot, 'Data\Sound\fx\MMESkyrimNetBridge\Hot Sounds\010.wav');
  AddSoundFile(PoolHot, 'Data\Sound\fx\MMESkyrimNetBridge\Hot Sounds\011.wav');
  PoolMedium := MakePool('MMEAlerts_SNDR_Medium');
  AddSoundFile(PoolMedium, 'Data\Sound\fx\MMESkyrimNetBridge\Medium Sounds\001.wav');
  AddSoundFile(PoolMedium, 'Data\Sound\fx\MMESkyrimNetBridge\Medium Sounds\002.wav');
  AddSoundFile(PoolMedium, 'Data\Sound\fx\MMESkyrimNetBridge\Medium Sounds\003.wav');
  AddSoundFile(PoolMedium, 'Data\Sound\fx\MMESkyrimNetBridge\Medium Sounds\004.wav');
  AddSoundFile(PoolMedium, 'Data\Sound\fx\MMESkyrimNetBridge\Medium Sounds\005.wav');
  AddSoundFile(PoolMedium, 'Data\Sound\fx\MMESkyrimNetBridge\Medium Sounds\006.wav');
  AddSoundFile(PoolMedium, 'Data\Sound\fx\MMESkyrimNetBridge\Medium Sounds\007.wav');
  AddSoundFile(PoolMedium, 'Data\Sound\fx\MMESkyrimNetBridge\Medium Sounds\008.wav');
  AddSoundFile(PoolMedium, 'Data\Sound\fx\MMESkyrimNetBridge\Medium Sounds\009.wav');
  AddSoundFile(PoolMedium, 'Data\Sound\fx\MMESkyrimNetBridge\Medium Sounds\010.wav');
  AddSoundFile(PoolMedium, 'Data\Sound\fx\MMESkyrimNetBridge\Medium Sounds\011.wav');
  AddSoundFile(PoolMedium, 'Data\Sound\fx\MMESkyrimNetBridge\Medium Sounds\012.wav');
  AddSoundFile(PoolMedium, 'Data\Sound\fx\MMESkyrimNetBridge\Medium Sounds\013.wav');
  AddSoundFile(PoolMedium, 'Data\Sound\fx\MMESkyrimNetBridge\Medium Sounds\014.wav');
  AddSoundFile(PoolMedium, 'Data\Sound\fx\MMESkyrimNetBridge\Medium Sounds\015.wav');
  AddSoundFile(PoolMedium, 'Data\Sound\fx\MMESkyrimNetBridge\Medium Sounds\016.wav');
  AddSoundFile(PoolMedium, 'Data\Sound\fx\MMESkyrimNetBridge\Medium Sounds\017.wav');
  AddSoundFile(PoolMedium, 'Data\Sound\fx\MMESkyrimNetBridge\Medium Sounds\018.wav');
  AddSoundFile(PoolMedium, 'Data\Sound\fx\MMESkyrimNetBridge\Medium Sounds\019.wav');
  AddSoundFile(PoolMedium, 'Data\Sound\fx\MMESkyrimNetBridge\Medium Sounds\020.wav');
  AddSoundFile(PoolMedium, 'Data\Sound\fx\MMESkyrimNetBridge\Medium Sounds\021.wav');
  AddSoundFile(PoolMedium, 'Data\Sound\fx\MMESkyrimNetBridge\Medium Sounds\022.wav');
  AddSoundFile(PoolMedium, 'Data\Sound\fx\MMESkyrimNetBridge\Medium Sounds\023.wav');
  AddSoundFile(PoolMedium, 'Data\Sound\fx\MMESkyrimNetBridge\Medium Sounds\024.wav');
  AddSoundFile(PoolMedium, 'Data\Sound\fx\MMESkyrimNetBridge\Medium Sounds\025.wav');
  AddSoundFile(PoolMedium, 'Data\Sound\fx\MMESkyrimNetBridge\Medium Sounds\026.wav');
  AddSoundFile(PoolMedium, 'Data\Sound\fx\MMESkyrimNetBridge\Medium Sounds\027.wav');
  AddSoundFile(PoolMedium, 'Data\Sound\fx\MMESkyrimNetBridge\Medium Sounds\028.wav');
  AddSoundFile(PoolMedium, 'Data\Sound\fx\MMESkyrimNetBridge\Medium Sounds\029.wav');
  AddSoundFile(PoolMedium, 'Data\Sound\fx\MMESkyrimNetBridge\Medium Sounds\030.wav');
  AddSoundFile(PoolMedium, 'Data\Sound\fx\MMESkyrimNetBridge\Medium Sounds\031.wav');
  AddSoundFile(PoolMedium, 'Data\Sound\fx\MMESkyrimNetBridge\Medium Sounds\032.wav');
  AddSoundFile(PoolMedium, 'Data\Sound\fx\MMESkyrimNetBridge\Medium Sounds\033.wav');
  AddSoundFile(PoolMedium, 'Data\Sound\fx\MMESkyrimNetBridge\Medium Sounds\034.wav');
  AddSoundFile(PoolMedium, 'Data\Sound\fx\MMESkyrimNetBridge\Medium Sounds\035.wav');
  AddSoundFile(PoolMedium, 'Data\Sound\fx\MMESkyrimNetBridge\Medium Sounds\036.wav');
  AddSoundFile(PoolMedium, 'Data\Sound\fx\MMESkyrimNetBridge\Medium Sounds\037.wav');
  AddSoundFile(PoolMedium, 'Data\Sound\fx\MMESkyrimNetBridge\Medium Sounds\038.wav');
  AddSoundFile(PoolMedium, 'Data\Sound\fx\MMESkyrimNetBridge\Medium Sounds\039.wav');
  AddSoundFile(PoolMedium, 'Data\Sound\fx\MMESkyrimNetBridge\Medium Sounds\040.wav');
  AddSoundFile(PoolMedium, 'Data\Sound\fx\MMESkyrimNetBridge\Medium Sounds\041.wav');
  AddSoundFile(PoolMedium, 'Data\Sound\fx\MMESkyrimNetBridge\Medium Sounds\042.wav');
  AddSoundFile(PoolMedium, 'Data\Sound\fx\MMESkyrimNetBridge\Medium Sounds\043.wav');
  AddSoundFile(PoolMedium, 'Data\Sound\fx\MMESkyrimNetBridge\Medium Sounds\044.wav');
  AddSoundFile(PoolMedium, 'Data\Sound\fx\MMESkyrimNetBridge\Medium Sounds\045.wav');
  AddSoundFile(PoolMedium, 'Data\Sound\fx\MMESkyrimNetBridge\Medium Sounds\046.wav');
  AddSoundFile(PoolMedium, 'Data\Sound\fx\MMESkyrimNetBridge\Medium Sounds\047.wav');
  AddSoundFile(PoolMedium, 'Data\Sound\fx\MMESkyrimNetBridge\Medium Sounds\048.wav');
  AddSoundFile(PoolMedium, 'Data\Sound\fx\MMESkyrimNetBridge\Medium Sounds\049.wav');
  AddSoundFile(PoolMedium, 'Data\Sound\fx\MMESkyrimNetBridge\Medium Sounds\050.wav');
  AddSoundFile(PoolMedium, 'Data\Sound\fx\MMESkyrimNetBridge\Medium Sounds\051.wav');
  AddSoundFile(PoolMedium, 'Data\Sound\fx\MMESkyrimNetBridge\Medium Sounds\052.wav');
  AddSoundFile(PoolMedium, 'Data\Sound\fx\MMESkyrimNetBridge\Medium Sounds\053.wav');
  AddSoundFile(PoolMedium, 'Data\Sound\fx\MMESkyrimNetBridge\Medium Sounds\054.wav');
  AddSoundFile(PoolMedium, 'Data\Sound\fx\MMESkyrimNetBridge\Medium Sounds\055.wav');
  PoolMild := MakePool('MMEAlerts_SNDR_Mild');
  AddSoundFile(PoolMild, 'Data\Sound\fx\MMESkyrimNetBridge\Mild Sounds\001.wav');
  AddSoundFile(PoolMild, 'Data\Sound\fx\MMESkyrimNetBridge\Mild Sounds\002.wav');
  AddSoundFile(PoolMild, 'Data\Sound\fx\MMESkyrimNetBridge\Mild Sounds\003.wav');
  AddSoundFile(PoolMild, 'Data\Sound\fx\MMESkyrimNetBridge\Mild Sounds\004.wav');
  AddSoundFile(PoolMild, 'Data\Sound\fx\MMESkyrimNetBridge\Mild Sounds\005.wav');
  AddSoundFile(PoolMild, 'Data\Sound\fx\MMESkyrimNetBridge\Mild Sounds\006.wav');
  AddSoundFile(PoolMild, 'Data\Sound\fx\MMESkyrimNetBridge\Mild Sounds\007.wav');
  AddSoundFile(PoolMild, 'Data\Sound\fx\MMESkyrimNetBridge\Mild Sounds\008.wav');
  AddSoundFile(PoolMild, 'Data\Sound\fx\MMESkyrimNetBridge\Mild Sounds\009.wav');
  AddSoundFile(PoolMild, 'Data\Sound\fx\MMESkyrimNetBridge\Mild Sounds\010.wav');
  AddSoundFile(PoolMild, 'Data\Sound\fx\MMESkyrimNetBridge\Mild Sounds\011.wav');
  AddSoundFile(PoolMild, 'Data\Sound\fx\MMESkyrimNetBridge\Mild Sounds\012.wav');
  AddSoundFile(PoolMild, 'Data\Sound\fx\MMESkyrimNetBridge\Mild Sounds\013.wav');
  AddSoundFile(PoolMild, 'Data\Sound\fx\MMESkyrimNetBridge\Mild Sounds\014.wav');
  AddSoundFile(PoolMild, 'Data\Sound\fx\MMESkyrimNetBridge\Mild Sounds\015.wav');
  AddSoundFile(PoolMild, 'Data\Sound\fx\MMESkyrimNetBridge\Mild Sounds\016.wav');
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
