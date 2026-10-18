unit UserScript;

const
  DescriptorLocalID = $0008B0;
  MarkerLocalID = $0008B1;
  DescriptorEditorID = 'MMEAlerts_SNDR_BreastSlap';
  MarkerEditorID = 'MMEAlerts_SOUN_BreastSlap';

var
  TargetFile, SkyrimFile, DescriptorTemplate, MarkerTemplate: IInterface;

function FindFileByName(aName: string): IInterface;
var
  i: Integer;
begin
  Result := nil;
  for i := 0 to FileCount - 1 do
    if SameText(GetFileName(FileByIndex(i)), aName) then begin
      Result := FileByIndex(i);
      Exit;
    end;
end;

function LocalFormID(aRecord: IInterface): Cardinal;
begin
  { MMEAlert is ESL-flagged. Its object ID occupies the low twelve bits. }
  Result := GetLoadOrderFormID(aRecord) and $00000FFF;
end;

function FindRecordByLocalFormID(aLocalFormID: Cardinal): IInterface;
var
  i: Integer;
  candidate: IInterface;
begin
  { RecordByFormID's full-plugin master-index formula cannot address an ESL
    load-order slot such as FE005. Enumerate this small plugin instead. }
  Result := nil;
  for i := 0 to RecordCount(TargetFile) - 1 do begin
    candidate := RecordByIndex(TargetFile, i);
    if Assigned(candidate) and (LocalFormID(candidate) = aLocalFormID) then begin
      Result := candidate;
      Exit;
    end;
  end;
end;

procedure AssignLocalFormID(aRecord: IInterface; aLocalFormID: Cardinal; aExpectedEditorID: string);
var
  occupant: IInterface;
  loadOrderPrefix: Cardinal;
begin
  if LocalFormID(aRecord) = aLocalFormID then Exit;
  occupant := FindRecordByLocalFormID(aLocalFormID);
  if Assigned(occupant) and (EditorID(occupant) <> aExpectedEditorID) then
    raise Exception.Create('Required FormID ' + IntToHex(aLocalFormID, 6) +
      ' is occupied by ' + EditorID(occupant) + '. No changes were saved.');
  { Preserve FE + light-plugin index while replacing only the object ID. }
  loadOrderPrefix := GetLoadOrderFormID(aRecord) and $FFFFF000;
  SetLoadOrderFormID(aRecord, loadOrderPrefix or aLocalFormID);
end;

procedure ClearSoundFiles(aDescriptor: IInterface);
var
  sounds: IInterface;
begin
  sounds := ElementByPath(aDescriptor, 'Sounds');
  if not Assigned(sounds) then Exit;
  while ElementCount(sounds) > 0 do
    Remove(ElementByIndex(sounds, 0));
end;

procedure AddSoundFile(aDescriptor: IInterface; aPath: string);
var
  sounds, entry: IInterface;
begin
  sounds := ElementByPath(aDescriptor, 'Sounds');
  entry := ElementAssign(sounds, HighInteger, nil, False);
  SetElementEditValues(entry, 'ANAM - File Name', aPath);
end;

function Initialize: Integer;
var
  descriptor, marker, occupant: IInterface;
begin
  Result := 1;
  TargetFile := FindFileByName('MMEAlert.esp');
  SkyrimFile := FindFileByName('Skyrim.esm');
  if not Assigned(TargetFile) or not Assigned(SkyrimFile) then begin
    AddMessage('ERROR: Load Skyrim.esm and MMEAlert.esp before running this script.');
    Exit;
  end;

  occupant := FindRecordByLocalFormID(DescriptorLocalID);
  if Assigned(occupant) and (EditorID(occupant) <> DescriptorEditorID) then begin
    AddMessage('ERROR: FormID 0008B0 is occupied by ' + EditorID(occupant) + '. No changes made.');
    Exit;
  end;
  occupant := FindRecordByLocalFormID(MarkerLocalID);
  if Assigned(occupant) and (EditorID(occupant) <> MarkerEditorID) then begin
    AddMessage('ERROR: FormID 0008B1 is occupied by ' + EditorID(occupant) + '. No changes made.');
    Exit;
  end;

  DescriptorTemplate := RecordByFormID(SkyrimFile, $00000E48, True);
  MarkerTemplate := RecordByFormID(SkyrimFile, $00000E06, True);
  if not Assigned(DescriptorTemplate) or not Assigned(MarkerTemplate) then begin
    AddMessage('ERROR: Vanilla sound templates could not be resolved. No changes made.');
    Exit;
  end;

  descriptor := MainRecordByEditorID(GroupBySignature(TargetFile, 'SNDR'), DescriptorEditorID);
  if not Assigned(descriptor) then
    descriptor := wbCopyElementToFile(DescriptorTemplate, TargetFile, True, True);
  SetEditorID(descriptor, DescriptorEditorID);
  AssignLocalFormID(descriptor, DescriptorLocalID, DescriptorEditorID);
  ClearSoundFiles(descriptor);
  AddSoundFile(descriptor, 'fx\MMESkyrimNetBridge\Tit Slap Sounds\tit slap sound loop.wav');

  marker := MainRecordByEditorID(GroupBySignature(TargetFile, 'SOUN'), MarkerEditorID);
  if not Assigned(marker) then
    marker := wbCopyElementToFile(MarkerTemplate, TargetFile, True, True);
  SetEditorID(marker, MarkerEditorID);
  AssignLocalFormID(marker, MarkerLocalID, MarkerEditorID);
  SetElementEditValues(marker, 'SDSC', Name(descriptor));

  AddMessage('SUCCESS: Added/updated breast-slap SNDR 0008B0 and SOUN 0008B1.');
  AddMessage('Save MMEAlert.esp, close SSEEdit, then hand control back to Codex.');
  Result := 0;
end;

end.
