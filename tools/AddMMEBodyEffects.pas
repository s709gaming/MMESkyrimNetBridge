unit UserScript;

const
  TargetPluginName = 'MMEAlert.esp';
  SourceEffectEditorID = 'MMEAlerts_PlayerMonitorEffect';
  SourceAbilityEditorID = 'MMEAlerts_PlayerMonitorAbility';
  BodyEffectEditorID = 'MMEExt_MilkBurdenDisplayEffect';
  BodyAbilityEditorID = 'MMEExt_MilkBurdenDisplayAbility';
  BodyEffectLocalID = $0008C0;
  BodyAbilityLocalID = $0008C1;
  MilkWeightEffectEditorID = 'MMEExt_MilkWeightDisplayEffect';
  MilkWeightAbilityEditorID = 'MMEExt_MilkWeightDisplayAbility';
  MilkWeightEffectLocalID = $0008C2;
  MilkWeightAbilityLocalID = $0008C3;

var TargetFile: IInterface;

procedure SavePatchedPlugin;
var outputPath: string; outputStream: TFileStream;
begin
  outputPath := wbDataPath + 'MMEAlert.BodyEffects.patched';
  outputStream := TFileStream.Create(outputPath, fmCreate);
  try
    FileWriteToStream(TargetFile, outputStream, False);
  finally
    outputStream.Free;
  end;
  AddMessage('OUTPUT: ' + outputPath);
end;

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

function LocalFormID(aRecord: IInterface): Cardinal;
begin
  Result := GetLoadOrderFormID(aRecord) and $00000FFF;
end;

function FindRecordByLocalFormID(aLocalFormID: Cardinal): IInterface;
var i: Integer; candidate: IInterface;
begin
  Result := nil;
  for i := 0 to RecordCount(TargetFile) - 1 do begin
    candidate := RecordByIndex(TargetFile, i);
    if Assigned(candidate) and (LocalFormID(candidate) = aLocalFormID) then begin
      Result := candidate;
      Exit;
    end;
  end;
end;

function FindRecordByEditorIDRecursive(aElement: IInterface;
  aSignature, aEditorID: string): IInterface;
var i: Integer;
begin
  Result := nil;
  if not Assigned(aElement) then Exit;
  if (Signature(aElement) = aSignature) and SameText(EditorID(aElement), aEditorID) then begin
    Result := aElement;
    Exit;
  end;
  for i := 0 to ElementCount(aElement) - 1 do begin
    Result := FindRecordByEditorIDRecursive(ElementByIndex(aElement, i), aSignature, aEditorID);
    if Assigned(Result) then Exit;
  end;
end;

function FindEffectData(aElement: IInterface): IInterface;
var i: Integer;
begin
  Result := nil;
  if not Assigned(aElement) then Exit;
  if Assigned(ElementByName(aElement, 'Archtype')) and
     Assigned(ElementByName(aElement, 'Casting Type')) and
     Assigned(ElementByName(aElement, 'Delivery')) and
     Assigned(ElementByName(aElement, 'Flags')) then begin
    Result := aElement;
    Exit;
  end;
  for i := 0 to ElementCount(aElement) - 1 do begin
    Result := FindEffectData(ElementByIndex(aElement, i));
    if Assigned(Result) then Exit;
  end;
end;

procedure AssignLocalFormID(aRecord: IInterface; aLocalFormID: Cardinal;
  aExpectedEditorID: string);
var occupant: IInterface; prefix: Cardinal;
begin
  if LocalFormID(aRecord) = aLocalFormID then Exit;
  occupant := FindRecordByLocalFormID(aLocalFormID);
  if Assigned(occupant) and not SameText(EditorID(occupant), aExpectedEditorID) then
    raise Exception.Create('Required FormID ' + IntToHex(aLocalFormID, 6) +
      ' is occupied by ' + EditorID(occupant) + '.');
  prefix := GetLoadOrderFormID(aRecord) and $FFFFF000;
  SetLoadOrderFormID(aRecord, prefix or aLocalFormID);
end;

function Initialize: Integer;
var sourceEffect, sourceAbility, bodyEffect, bodyAbility,
    milkWeightEffect, milkWeightAbility: IInterface;
    effectData, spellData, effects, effectRow, vmad, occupant: IInterface;
begin
  Result := 1;
  TargetFile := FindFileByName(TargetPluginName);
  if not Assigned(TargetFile) then begin
    AddMessage('ERROR: Load MMEAlert.esp and its masters.');
    Exit;
  end;
  occupant := FindRecordByLocalFormID(BodyEffectLocalID);
  if Assigned(occupant) and not SameText(EditorID(occupant), BodyEffectEditorID) then begin
    AddMessage('ERROR: 0008C0 is occupied by ' + EditorID(occupant) + '.');
    Exit;
  end;
  occupant := FindRecordByLocalFormID(BodyAbilityLocalID);
  if Assigned(occupant) and not SameText(EditorID(occupant), BodyAbilityEditorID) then begin
    AddMessage('ERROR: 0008C1 is occupied by ' + EditorID(occupant) + '.');
    Exit;
  end;
  occupant := FindRecordByLocalFormID(MilkWeightEffectLocalID);
  if Assigned(occupant) and not SameText(EditorID(occupant), MilkWeightEffectEditorID) then begin
    AddMessage('ERROR: 0008C2 is occupied by ' + EditorID(occupant) + '.');
    Exit;
  end;
  occupant := FindRecordByLocalFormID(MilkWeightAbilityLocalID);
  if Assigned(occupant) and not SameText(EditorID(occupant), MilkWeightAbilityEditorID) then begin
    AddMessage('ERROR: 0008C3 is occupied by ' + EditorID(occupant) + '.');
    Exit;
  end;
  sourceEffect := FindRecordByEditorIDRecursive(GroupBySignature(TargetFile, 'MGEF'), 'MGEF', SourceEffectEditorID);
  sourceAbility := FindRecordByEditorIDRecursive(GroupBySignature(TargetFile, 'SPEL'), 'SPEL', SourceAbilityEditorID);
  if not Assigned(sourceEffect) or not Assigned(sourceAbility) then begin
    AddMessage('ERROR: Existing player-monitor templates are missing.');
    Exit;
  end;

  bodyEffect := FindRecordByEditorIDRecursive(GroupBySignature(TargetFile, 'MGEF'), 'MGEF', BodyEffectEditorID);
  if not Assigned(bodyEffect) then
    bodyEffect := wbCopyElementToFile(sourceEffect, TargetFile, True, True);
  SetEditorID(bodyEffect, BodyEffectEditorID);
  AssignLocalFormID(bodyEffect, BodyEffectLocalID, BodyEffectEditorID);
  SetElementEditValues(bodyEffect, 'FULL', 'Milk Burden');
  SetElementEditValues(bodyEffect, 'DNAM', 'Movement speed reduced by <mag>%.');
  effectData := FindEffectData(bodyEffect);
  if not Assigned(effectData) then begin
    AddMessage('ERROR: Magic-effect scalar data is unavailable.');
    Exit;
  end;
  SetNativeValue(ElementByName(effectData, 'Archtype'), 1);
  SetNativeValue(ElementByName(effectData, 'Flags'), $00000E04);
  SetNativeValue(ElementByName(effectData, 'Base Cost'), 0);
  SetNativeValue(ElementByName(effectData, 'Magic Skill'), -1);
  SetNativeValue(ElementByName(effectData, 'Resist Value'), -1);
  SetNativeValue(ElementByName(effectData, 'Actor Value'), -1);
  SetNativeValue(ElementByName(effectData, 'Second Actor Value'), -1);
  SetNativeValue(ElementByName(effectData, 'Casting Type'), 0);
  SetNativeValue(ElementByName(effectData, 'Delivery'), 0);
  vmad := ElementBySignature(bodyEffect, 'VMAD');
  if Assigned(vmad) then Remove(vmad);

  bodyAbility := FindRecordByEditorIDRecursive(GroupBySignature(TargetFile, 'SPEL'), 'SPEL', BodyAbilityEditorID);
  if not Assigned(bodyAbility) then
    bodyAbility := wbCopyElementToFile(sourceAbility, TargetFile, True, True);
  SetEditorID(bodyAbility, BodyAbilityEditorID);
  AssignLocalFormID(bodyAbility, BodyAbilityLocalID, BodyAbilityEditorID);
  SetElementEditValues(bodyAbility, 'FULL', 'Milk Burden');
  SetElementEditValues(bodyAbility, 'DESC', 'Movement speed reduced by <mag>%.');
  spellData := ElementBySignature(bodyAbility, 'SPIT');
  SetElementNativeValues(spellData, 'Type', 4);
  SetElementNativeValues(spellData, 'Cast Type', 0);
  SetElementNativeValues(spellData, 'Target Type', 0);
  SetElementNativeValues(spellData, 'Flags', 0);
  SetElementNativeValues(spellData, 'Base Cost', 0);
  effects := ElementByPath(bodyAbility, 'Effects');
  while ElementCount(effects) > 1 do
    Remove(ElementByIndex(effects, ElementCount(effects) - 1));
  effectRow := ElementByIndex(effects, 0);
  SetElementEditValues(effectRow, 'EFID', Name(bodyEffect));
  SetElementNativeValues(effectRow, 'EFIT\Magnitude', 1);
  SetElementNativeValues(effectRow, 'EFIT\Area', 0);
  SetElementNativeValues(effectRow, 'EFIT\Duration', 0);

  milkWeightEffect := FindRecordByEditorIDRecursive(GroupBySignature(TargetFile, 'MGEF'), 'MGEF', MilkWeightEffectEditorID);
  if not Assigned(milkWeightEffect) then
    milkWeightEffect := wbCopyElementToFile(sourceEffect, TargetFile, True, True);
  SetEditorID(milkWeightEffect, MilkWeightEffectEditorID);
  AssignLocalFormID(milkWeightEffect, MilkWeightEffectLocalID, MilkWeightEffectEditorID);
  SetElementEditValues(milkWeightEffect, 'FULL', 'Milk Weight');
  SetElementEditValues(milkWeightEffect, 'DNAM', 'Carried milk reduces carry capacity by <mag> points.');
  effectData := FindEffectData(milkWeightEffect);
  if not Assigned(effectData) then begin
    AddMessage('ERROR: Milk Weight magic-effect scalar data is unavailable.');
    Exit;
  end;
  SetNativeValue(ElementByName(effectData, 'Archtype'), 1);
  SetNativeValue(ElementByName(effectData, 'Flags'), $00000E04);
  SetNativeValue(ElementByName(effectData, 'Base Cost'), 0);
  SetNativeValue(ElementByName(effectData, 'Magic Skill'), -1);
  SetNativeValue(ElementByName(effectData, 'Resist Value'), -1);
  SetNativeValue(ElementByName(effectData, 'Actor Value'), -1);
  SetNativeValue(ElementByName(effectData, 'Second Actor Value'), -1);
  SetNativeValue(ElementByName(effectData, 'Casting Type'), 0);
  SetNativeValue(ElementByName(effectData, 'Delivery'), 0);
  vmad := ElementBySignature(milkWeightEffect, 'VMAD');
  if Assigned(vmad) then Remove(vmad);

  milkWeightAbility := FindRecordByEditorIDRecursive(GroupBySignature(TargetFile, 'SPEL'), 'SPEL', MilkWeightAbilityEditorID);
  if not Assigned(milkWeightAbility) then
    milkWeightAbility := wbCopyElementToFile(sourceAbility, TargetFile, True, True);
  SetEditorID(milkWeightAbility, MilkWeightAbilityEditorID);
  AssignLocalFormID(milkWeightAbility, MilkWeightAbilityLocalID, MilkWeightAbilityEditorID);
  SetElementEditValues(milkWeightAbility, 'FULL', 'Milk Weight');
  SetElementEditValues(milkWeightAbility, 'DESC', 'Carried milk reduces carry capacity by <mag> points.');
  spellData := ElementBySignature(milkWeightAbility, 'SPIT');
  SetElementNativeValues(spellData, 'Type', 4);
  SetElementNativeValues(spellData, 'Cast Type', 0);
  SetElementNativeValues(spellData, 'Target Type', 0);
  SetElementNativeValues(spellData, 'Flags', 0);
  SetElementNativeValues(spellData, 'Base Cost', 0);
  effects := ElementByPath(milkWeightAbility, 'Effects');
  while ElementCount(effects) > 1 do
    Remove(ElementByIndex(effects, ElementCount(effects) - 1));
  effectRow := ElementByIndex(effects, 0);
  SetElementEditValues(effectRow, 'EFID', Name(milkWeightEffect));
  SetElementNativeValues(effectRow, 'EFIT\Magnitude', 1);
  SetElementNativeValues(effectRow, 'EFIT\Area', 0);
  SetElementNativeValues(effectRow, 'EFIT\Duration', 0);

  SavePatchedPlugin;
  AddMessage('SUCCESS: Added/updated Milk Burden 0008C0/0008C1 and Milk Weight 0008C2/0008C3.');
  Result := 0;
end;

end.
