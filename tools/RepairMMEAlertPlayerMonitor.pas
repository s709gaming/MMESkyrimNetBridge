unit UserScript;

var
  TargetFile, SpellRecord, EffectRecord, Effects, EffectEntry, SpellData: IInterface;

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

function Initialize: Integer;
begin
  Result := 1;
  TargetFile := FindFileByName('MMEAlert.esp');
  if not Assigned(TargetFile) then begin
    AddMessage('ERROR: Load MMEAlert.esp.');
    Exit;
  end;

  SpellRecord := MainRecordByEditorID(GroupBySignature(TargetFile, 'SPEL'),
    'MMEAlerts_PlayerMonitorAbility');
  EffectRecord := MainRecordByEditorID(GroupBySignature(TargetFile, 'MGEF'),
    'MMEAlerts_PlayerMonitorEffect');
  if not Assigned(SpellRecord) or not Assigned(EffectRecord) then begin
    AddMessage('ERROR: Player monitor spell or effect record is missing.');
    Exit;
  end;

  SpellData := ElementBySignature(SpellRecord, 'SPIT');
  if not Assigned(SpellData) then begin
    AddMessage('ERROR: Monitor spell has no SPIT data.');
    Exit;
  end;
  AddMessage('Previous native spell type: ' + IntToStr(GetElementNativeValues(SpellData, 'Type')));
  SetElementNativeValues(SpellData, 'Type', 4);

  Effects := ElementByPath(SpellRecord, 'Effects');
  if not Assigned(Effects) or (ElementCount(Effects) = 0) then begin
    AddMessage('ERROR: Monitor ability has no effects.');
    Exit;
  end;
  EffectEntry := ElementByIndex(Effects, 0);
  SetElementEditValues(EffectEntry, 'EFID', Name(EffectRecord));

  AddMessage('New native spell type: ' + IntToStr(GetElementNativeValues(SpellData, 'Type')));
  if GetElementNativeValues(SpellData, 'Type') <> 4 then begin
    AddMessage('ERROR: Spell type write failed; expected native value 4.');
    Exit;
  end;
  AddMessage('Linked effect: ' + GetElementEditValues(EffectEntry, 'EFID'));
  AddMessage('MME Alerts player monitor repair complete.');
  Result := 0;
end;

end.
