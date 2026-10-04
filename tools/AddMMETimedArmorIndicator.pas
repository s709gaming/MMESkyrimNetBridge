unit UserScript;

{
  Adds the harmless, visible Active Effects marker used by MMETimedArmorLock.
  Load MMEAlert.esp and its masters in SSEEdit, run this script, then save.
  The installer copies the existing player-monitor ability as a structurally
  proven template, removes its VMAD, and assigns the next two free local IDs.
}

const
  TargetPluginName = 'MMEAlert.esp';
  SourceEffectEditorID = 'MMEAlerts_PlayerMonitorEffect';
  SourceAbilityEditorID = 'MMEAlerts_PlayerMonitorAbility';
  IndicatorEffectEditorID = 'MMEExt_TimedArmorIndicatorEffect';
  IndicatorAbilityEditorID = 'MMEExt_TimedArmorIndicatorAbility';

var
  TargetFile: IInterface;

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

function FindRecordByEditorIDRecursive(aElement: IInterface;
  aSignature, aEditorID: string): IInterface;
var i: Integer;
begin
  Result := nil;
  if not Assigned(aElement) then
    Exit;
  if (Signature(aElement) = aSignature) and
     SameText(EditorID(aElement), aEditorID) then begin
    Result := aElement;
    Exit;
  end;
  for i := 0 to ElementCount(aElement) - 1 do begin
    Result := FindRecordByEditorIDRecursive(ElementByIndex(aElement, i),
      aSignature, aEditorID);
    if Assigned(Result) then
      Exit;
  end;
end;

function FindEffectData(aElement: IInterface): IInterface;
var i: Integer;
begin
  Result := nil;
  if not Assigned(aElement) then
    Exit;
  if Assigned(ElementByName(aElement, 'Archtype')) and
     Assigned(ElementByName(aElement, 'Casting Type')) and
     Assigned(ElementByName(aElement, 'Delivery')) and
     Assigned(ElementByName(aElement, 'Flags')) then begin
    Result := aElement;
    Exit;
  end;
  for i := 0 to ElementCount(aElement) - 1 do begin
    Result := FindEffectData(ElementByIndex(aElement, i));
    if Assigned(Result) then
      Exit;
  end;
end;

function NewOrExisting(aSignature, aEditorID: string;
  aTemplate: IInterface): IInterface;
var records: IInterface;
begin
  records := GroupBySignature(TargetFile, aSignature);
  Result := FindRecordByEditorIDRecursive(records, aSignature, aEditorID);
  if Assigned(Result) then
    Exit;
  Result := wbCopyElementToFile(aTemplate, TargetFile, True, True);
  if Assigned(Result) then
    SetEditorID(Result, aEditorID);
end;

function Initialize: Integer;
var
  sourceEffect, sourceAbility, indicatorEffect, indicatorAbility: IInterface;
  effectData, spellData, effects, effectRow, vmad: IInterface;
begin
  Result := 1;
  TargetFile := FindFileByName(TargetPluginName);
  if not Assigned(TargetFile) then begin
    AddMessage('ERROR: Load MMEAlert.esp and its masters.');
    Exit;
  end;
  sourceEffect := FindRecordByEditorIDRecursive(
    GroupBySignature(TargetFile, 'MGEF'), 'MGEF', SourceEffectEditorID);
  sourceAbility := FindRecordByEditorIDRecursive(
    GroupBySignature(TargetFile, 'SPEL'), 'SPEL', SourceAbilityEditorID);
  if not Assigned(sourceEffect) or not Assigned(sourceAbility) then begin
    AddMessage('ERROR: Existing player-monitor templates are missing.');
    Exit;
  end;

  indicatorEffect := NewOrExisting('MGEF', IndicatorEffectEditorID, sourceEffect);
  indicatorAbility := NewOrExisting('SPEL', IndicatorAbilityEditorID, sourceAbility);
  if not Assigned(indicatorEffect) or not Assigned(indicatorAbility) then begin
    AddMessage('ERROR: Could not create indicator records.');
    Exit;
  end;

  SetElementEditValues(indicatorEffect, 'FULL', 'Special Armor Bond');
  effectData := FindEffectData(indicatorEffect);
  if not Assigned(effectData) then begin
    AddMessage('ERROR: Magic-effect scalar data is unavailable.');
    Exit;
  end;
  SetNativeValue(ElementByName(effectData, 'Archtype'), 1);
  SetNativeValue(ElementByName(effectData, 'Flags'), $00000E00);
  SetNativeValue(ElementByName(effectData, 'Base Cost'), 0);
  SetNativeValue(ElementByName(effectData, 'Magic Skill'), -1);
  SetNativeValue(ElementByName(effectData, 'Resist Value'), -1);
  SetNativeValue(ElementByName(effectData, 'Actor Value'), -1);
  SetNativeValue(ElementByName(effectData, 'Second Actor Value'), -1);
  SetNativeValue(ElementByName(effectData, 'Casting Type'), 0);
  SetNativeValue(ElementByName(effectData, 'Delivery'), 0);
  vmad := ElementBySignature(indicatorEffect, 'VMAD');
  if Assigned(vmad) then
    Remove(vmad);

  SetElementEditValues(indicatorAbility, 'FULL', 'Special Armor Bond');
  spellData := ElementBySignature(indicatorAbility, 'SPIT');
  SetElementNativeValues(spellData, 'Type', 4);
  SetElementNativeValues(spellData, 'Cast Type', 0);
  SetElementNativeValues(spellData, 'Target Type', 0);
  SetElementNativeValues(spellData, 'Flags', 0);
  SetElementNativeValues(spellData, 'Base Cost', 0);
  SetElementNativeValues(spellData, 'Charge Time', 0);
  effects := ElementByPath(indicatorAbility, 'Effects');
  while ElementCount(effects) > 1 do
    Remove(ElementByIndex(effects, ElementCount(effects) - 1));
  effectRow := ElementByIndex(effects, 0);
  SetElementEditValues(effectRow, 'EFID', Name(indicatorEffect));
  SetElementNativeValues(effectRow, 'EFIT\Magnitude', 0);
  SetElementNativeValues(effectRow, 'EFIT\Area', 0);
  SetElementNativeValues(effectRow, 'EFIT\Duration', 0);

  AddMessage('Timed armor indicator installed:');
  AddMessage('  ' + Name(indicatorEffect));
  AddMessage('  ' + Name(indicatorAbility));
  AddMessage('Save MMEAlert.esp and run Check for Errors.');
  Result := 0;
end;

end.
