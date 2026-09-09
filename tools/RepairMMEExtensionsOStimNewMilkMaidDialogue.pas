unit UserScript;

{
  Repairs both New Milk Maid entrances to use their matching stable backend
  gate only. Runtime validation stays in MMENewMilkMaid immediately before the
  scene starts.
}

const
  TargetPluginName = 'MMEAlert.esp';
  TargetInfoEditorID = 'MMEExt_NewMilkMaid';
  SexLabInfoEditorID = 'MMEExt_SexLabNewMilkMaid';
  SourceInfoEditorID = 'MMEExt_OStimBreastfeeding_NPCDrinks';
  OStimGateEditorID = 'MMEExt_OStimDialogueAvailable';
  SexLabGateEditorID = 'MMEExt_SexLabNewMilkMaidDialogueAvailable';

function FindRecord(aElement: IInterface; aSignature, aEditorID: string): IInterface;
var
  i: Integer;
begin
  Result := nil;
  if not Assigned(aElement) then Exit;
  if (Signature(aElement) = aSignature) and SameText(EditorID(aElement), aEditorID) then begin
    Result := aElement;
    Exit;
  end;
  for i := 0 to ElementCount(aElement) - 1 do begin
    Result := FindRecord(ElementByIndex(aElement, i), aSignature, aEditorID);
    if Assigned(Result) then Exit;
  end;
end;

function Initialize: Integer;
var
  i, j: Integer;
  targetFile, targetInfo, sexLabInfo, sourceInfo, ostimGate, sexLabGate,
    sourceConditions, sourceCondition, targetConditions, copiedCondition,
    parameter: IInterface;
begin
  Result := 1;
  targetFile := nil;
  for i := 0 to FileCount - 1 do
    if SameText(GetFileName(FileByIndex(i)), TargetPluginName) then
      targetFile := FileByIndex(i);
  if not Assigned(targetFile) then begin
    AddMessage('ERROR: MMEAlert.esp is not loaded.');
    Exit;
  end;

  targetInfo := FindRecord(GroupBySignature(targetFile, 'DIAL'), 'INFO', TargetInfoEditorID);
  sexLabInfo := FindRecord(GroupBySignature(targetFile, 'DIAL'), 'INFO', SexLabInfoEditorID);
  sourceInfo := FindRecord(GroupBySignature(targetFile, 'DIAL'), 'INFO', SourceInfoEditorID);
  ostimGate := FindRecord(GroupBySignature(targetFile, 'GLOB'), 'GLOB', OStimGateEditorID);
  sexLabGate := FindRecord(GroupBySignature(targetFile, 'GLOB'), 'GLOB', SexLabGateEditorID);
  if not Assigned(targetInfo) or not Assigned(sexLabInfo) or
     not Assigned(sourceInfo) or not Assigned(ostimGate) or
     not Assigned(sexLabGate) then begin
    AddMessage('ERROR: Required New Milk Maid records are incomplete.');
    Exit;
  end;

  sourceConditions := ElementByPath(sourceInfo, 'Conditions');
  targetConditions := ElementByPath(targetInfo, 'Conditions');
  if Assigned(targetConditions) then Remove(targetConditions);
  Add(targetInfo, 'Conditions', True);
  targetConditions := ElementByPath(targetInfo, 'Conditions');
  copiedCondition := nil;
  for j := 0 to ElementCount(sourceConditions) - 1 do begin
    sourceCondition := ElementByIndex(sourceConditions, j);
    if SameText(GetElementEditValues(sourceCondition, 'CTDA\Function'), 'GetGlobalValue') then
      copiedCondition := ElementAssign(targetConditions, HighInteger, sourceCondition, False);
  end;
  if not Assigned(copiedCondition) or (ElementCount(targetConditions) <> 1) then begin
    AddMessage('ERROR: Could not isolate the OStim Global condition.');
    Exit;
  end;
  parameter := ElementByPath(copiedCondition, 'CTDA\Parameter #1');
  SetEditValue(parameter, Name(ostimGate));
  if not Assigned(LinksTo(parameter)) or
     not Equals(MasterOrSelf(LinksTo(parameter)), MasterOrSelf(ostimGate)) then begin
    AddMessage('ERROR: Repaired condition does not resolve to the OStim gate.');
    Exit;
  end;
  targetConditions := ElementByPath(sexLabInfo, 'Conditions');
  if Assigned(targetConditions) then Remove(targetConditions);
  Add(sexLabInfo, 'Conditions', True);
  targetConditions := ElementByPath(sexLabInfo, 'Conditions');
  copiedCondition := nil;
  for j := 0 to ElementCount(sourceConditions) - 1 do begin
    sourceCondition := ElementByIndex(sourceConditions, j);
    if SameText(GetElementEditValues(sourceCondition, 'CTDA\Function'), 'GetGlobalValue') then
      copiedCondition := ElementAssign(targetConditions, HighInteger, sourceCondition, False);
  end;
  if not Assigned(copiedCondition) or (ElementCount(targetConditions) <> 1) then begin
    AddMessage('ERROR: Could not isolate the SexLab Global condition.');
    Exit;
  end;
  parameter := ElementByPath(copiedCondition, 'CTDA\Parameter #1');
  SetEditValue(parameter, Name(sexLabGate));
  if not Assigned(LinksTo(parameter)) or
     not Equals(MasterOrSelf(LinksTo(parameter)), MasterOrSelf(sexLabGate)) then begin
    AddMessage('ERROR: Repaired condition does not resolve to the SexLab gate.');
    Exit;
  end;
  AddMessage('SUCCESS: both New Milk Maid INFOs now use their matching stable backend gate.');
  Result := 0;
end;

end.
