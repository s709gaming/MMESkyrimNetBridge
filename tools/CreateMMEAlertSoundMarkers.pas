unit UserScript;

var
  TargetFile, SkyrimFile, MarkerTemplate: IInterface;
  CreatedCount, LinkedCount: Integer;

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

procedure MakeMarker(aDescriptorEditorID, aMarkerEditorID: string);
var descriptorRecord, markerRecord: IInterface;
begin
  descriptorRecord := MainRecordByEditorID(GroupBySignature(TargetFile, 'SNDR'), aDescriptorEditorID);
  if not Assigned(descriptorRecord) then begin
    AddMessage('ERROR: descriptor missing: ' + aDescriptorEditorID);
    Exit;
  end;

  markerRecord := MainRecordByEditorID(GroupBySignature(TargetFile, 'SOUN'), aMarkerEditorID);
  if not Assigned(markerRecord) then begin
    markerRecord := wbCopyElementToFile(MarkerTemplate, TargetFile, True, True);
    Inc(CreatedCount);
  end;
  SetEditorID(markerRecord, aMarkerEditorID);
  SetElementEditValues(markerRecord, 'SDSC', Name(descriptorRecord));
  Inc(LinkedCount);
end;

function Initialize: Integer;
var slot: Integer;
begin
  Result := 1;
  CreatedCount := 0;
  LinkedCount := 0;
  TargetFile := FindFileByName('MMEAlert.esp');
  SkyrimFile := FindFileByName('Skyrim.esm');
  if not Assigned(TargetFile) or not Assigned(SkyrimFile) then begin
    AddMessage('ERROR: Load Skyrim.esm and MMEAlert.esp before running this script.');
    Exit;
  end;

  MarkerTemplate := RecordByFormID(SkyrimFile, $00000E06, True);
  if not Assigned(MarkerTemplate) then begin
    AddMessage('ERROR: Skyrim SOUN template 00000E06 was not found.');
    Exit;
  end;

  for slot := 1 to 25 do begin
    MakeMarker('MMEAlerts_SNDR_Voice' + Format('%.2d', [slot]) + '_Mild',
      'MMEAlerts_SOUN_Voice' + Format('%.2d', [slot]) + '_Mild');
    MakeMarker('MMEAlerts_SNDR_Voice' + Format('%.2d', [slot]) + '_Medium',
      'MMEAlerts_SOUN_Voice' + Format('%.2d', [slot]) + '_Medium');
    MakeMarker('MMEAlerts_SNDR_Voice' + Format('%.2d', [slot]) + '_Hot',
      'MMEAlerts_SOUN_Voice' + Format('%.2d', [slot]) + '_Hot');
  end;

  AddMessage('MME Alerts sound markers complete.');
  AddMessage('New SOUN markers created: ' + IntToStr(CreatedCount));
  AddMessage('Markers linked to descriptors: ' + IntToStr(LinkedCount));
  Result := 0;
end;

end.
