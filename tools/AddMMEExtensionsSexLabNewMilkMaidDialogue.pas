unit UserScript;

{
  Splits New Milk Maid into mutually-exclusive OStim and SexLab entrances.

  - Preserves the existing working MMEExt_NewMilkMaid OStim INFO and restores
    its condition to MMEExt_OStimDialogueAvailable.
  - Repurposes the former neutral Global as the SexLab-only runtime gate.
  - Copies original MME INFO 05FE0E (player is source, NPC is drinker), keeping
    its conditions and bound MME_Dialogues properties.
  - Changes only the copied fragment script/function to MMENewMilkMaid and
    Fragment_CreateMilkMaidSexLab, then adds native Milk Maid eligibility.
  - Adds the new topic to MME's existing "Hey there" choice list.

  Safe to rerun by stable EditorID. The original MME INFO is never modified.
}

const
  TargetPluginName = 'MMEAlert.esp';
  MMEPluginName = 'MilkModNEW.esp';
  OriginalMMETopicEditorID = 'MME_Milking_Player_Topic';

  OStimTopicEditorID = 'MMEExt_NewMilkMaidTopic';
  OStimInfoEditorID = 'MMEExt_NewMilkMaid';
  OStimGateEditorID = 'MMEExt_OStimDialogueAvailable';
  OldNeutralGateEditorID = 'MMEExt_NewMilkMaidDialogueAvailable';

  SexLabTopicEditorID = 'MMEExt_SexLabNewMilkMaidTopic';
  SexLabInfoEditorID = 'MMEExt_SexLabNewMilkMaid';
  SexLabGateEditorID = 'MMEExt_SexLabNewMilkMaidDialogueAvailable';
  HandlerScriptName = 'MMENewMilkMaid';
  HandlerFragmentName = 'Fragment_CreateMilkMaidSexLab';
  PlayerPrompt = 'Wanna become a Milk Maid? Have a taste! Straight from the tap.';
  NPCResponse = 'I''d love a sip! Yummy!';

  SubjectMaidVariable = '::MME_SubjectMaid_var';
  SubjectSlaveVariable = '::MME_SubjectSlave_var';
  FreeMaidSlotsVariable = '::MME_FreeMaidSlots_var';

var
  TargetFile, MMEFile: IInterface;
  OStimTopic, OStimInfo, OStimGate, SexLabGate: IInterface;
  OriginalMMEInfo, OriginalMMETopic, OpeningInfo: IInterface;
  ExistingSexLabTopic, ExistingSexLabInfo: IInterface;

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

function FindRecordByEditorIDRecursive(aElement: IInterface;
  aSignature, aEditorID: string): IInterface;
var
  i: Integer;
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

function TreeHasExactValue(aElement: IInterface; aValue: string): Boolean;
var
  i: Integer;
begin
  Result := False;
  if not Assigned(aElement) then
    Exit;
  if SameText(GetEditValue(aElement), aValue) then begin
    Result := True;
    Exit;
  end;
  for i := 0 to ElementCount(aElement) - 1 do
    if TreeHasExactValue(ElementByIndex(aElement, i), aValue) then begin
      Result := True;
      Exit;
    end;
end;

procedure ReplaceTreeValue(aElement: IInterface; aOldValue, aNewValue: string);
var
  i: Integer;
begin
  if not Assigned(aElement) then
    Exit;
  if SameText(GetEditValue(aElement), aOldValue) then
    SetEditValue(aElement, aNewValue);
  for i := 0 to ElementCount(aElement) - 1 do
    ReplaceTreeValue(ElementByIndex(aElement, i), aOldValue, aNewValue);
end;

function FindConditionByVariable(aInfo: IInterface; aVariable: string): IInterface;
var
  conditions, condition: IInterface;
  i: Integer;
begin
  Result := nil;
  conditions := ElementByPath(aInfo, 'Conditions');
  if not Assigned(conditions) then
    Exit;
  for i := 0 to ElementCount(conditions) - 1 do begin
    condition := ElementByIndex(conditions, i);
    if SameText(GetElementEditValues(condition, 'CTDA\Function'),
        'GetVMQuestVariable') and
       SameText(GetElementEditValues(condition, 'CIS2'), aVariable) then begin
      Result := condition;
      Exit;
    end;
  end;
end;

function FindGlobalCondition(aInfo: IInterface): IInterface;
var
  conditions, condition: IInterface;
  i: Integer;
begin
  Result := nil;
  conditions := ElementByPath(aInfo, 'Conditions');
  if not Assigned(conditions) then
    Exit;
  for i := 0 to ElementCount(conditions) - 1 do begin
    condition := ElementByIndex(conditions, i);
    if SameText(GetElementEditValues(condition, 'CTDA\Function'),
        'GetGlobalValue') then begin
      Result := condition;
      Exit;
    end;
  end;
end;

function PointGlobalCondition(aCondition, aGlobal: IInterface): Boolean;
var
  parameter: IInterface;
begin
  Result := False;
  if not Assigned(aCondition) or not Assigned(aGlobal) then
    Exit;
  parameter := ElementByPath(aCondition, 'CTDA\Parameter #1');
  if not Assigned(parameter) then
    Exit;
  SetEditValue(parameter, Name(aGlobal));
  Result := Assigned(LinksTo(parameter)) and
    Equals(MasterOrSelf(LinksTo(parameter)), MasterOrSelf(aGlobal));
end;

function EnsureChoiceLink(aOpeningInfo, aTopic: IInterface): Boolean;
var
  links, item, template: IInterface;
  i: Integer;
begin
  Result := False;
  links := ElementByName(aOpeningInfo, 'Link To');
  if not Assigned(links) or (ElementCount(links) = 0) then
    Exit;
  for i := 0 to ElementCount(links) - 1 do begin
    item := ElementByIndex(links, i);
    if Assigned(LinksTo(item)) and
       Equals(MasterOrSelf(LinksTo(item)), MasterOrSelf(aTopic)) then begin
      Result := True;
      Exit;
    end;
  end;
  template := ElementByIndex(links, ElementCount(links) - 1);
  item := ElementAssign(links, HighInteger, template, False);
  if not Assigned(item) then
    Exit;
  SetEditValue(item, Name(aTopic));
  Result := Assigned(LinksTo(item)) and
    Equals(MasterOrSelf(LinksTo(item)), MasterOrSelf(aTopic));
end;

function FindOpeningInfo(aElement: IInterface): IInterface;
var
  i: Integer;
  vmad: IInterface;
begin
  Result := nil;
  if not Assigned(aElement) then
    Exit;
  if Signature(aElement) = 'INFO' then begin
    vmad := ElementBySignature(aElement, 'VMAD');
    if Assigned(vmad) and TreeHasExactValue(vmad, 'MME_Dialogues') and
       TreeHasExactValue(vmad, 'Fragment_00') then begin
      Result := aElement;
      Exit;
    end;
  end;
  for i := 0 to ElementCount(aElement) - 1 do begin
    Result := FindOpeningInfo(ElementByIndex(aElement, i));
    if Assigned(Result) then
      Exit;
  end;
end;

function FindOriginalSexLabInfo(aElement, aTopic: IInterface): IInterface;
var
  i: Integer;
  topicField, vmad: IInterface;
begin
  Result := nil;
  if not Assigned(aElement) then
    Exit;
  if Signature(aElement) = 'INFO' then begin
    topicField := ElementByName(aElement, 'Topic');
    vmad := ElementBySignature(aElement, 'VMAD');
    if Assigned(topicField) and Assigned(LinksTo(topicField)) and
       Equals(MasterOrSelf(LinksTo(topicField)), MasterOrSelf(aTopic)) and
       Assigned(vmad) and TreeHasExactValue(vmad, 'MME_Dialogues') and
       TreeHasExactValue(vmad, 'Fragment_02') then begin
      Result := aElement;
      Exit;
    end;
  end;
  for i := 0 to ElementCount(aElement) - 1 do begin
    Result := FindOriginalSexLabInfo(ElementByIndex(aElement, i), aTopic);
    if Assigned(Result) then
      Exit;
  end;
end;

function EnsureOpeningOverride: Boolean;
var
  winner: IInterface;
begin
  Result := False;
  winner := WinningOverride(OpeningInfo);
  if Assigned(winner) and Equals(GetFile(winner), TargetFile) then
    OpeningInfo := winner
  else begin
    AddRequiredElementMasters(winner, TargetFile, False);
    OpeningInfo := wbCopyElementToFile(winner, TargetFile, False, True);
  end;
  Result := Assigned(OpeningInfo);
end;

function RestoreOStimRouteAndGate: Boolean;
var
  gateCondition: IInterface;
begin
  Result := False;
  SetEditorID(SexLabGate, SexLabGateEditorID);
  SetElementNativeValues(SexLabGate, 'FLTV', 0.0);
  gateCondition := FindGlobalCondition(OStimInfo);
  if not PointGlobalCondition(gateCondition, OStimGate) then begin
    AddMessage('ERROR: Could not restore the existing OStim New Milk Maid gate.');
    Exit;
  end;
  Result := True;
end;

function CopyResponseText(aTargetInfo: IInterface): Boolean;
var
  sourceResponses, targetResponses, row: IInterface;
begin
  Result := False;
  sourceResponses := ElementByPath(OStimInfo, 'Responses');
  if not Assigned(sourceResponses) or (ElementCount(sourceResponses) <> 1) then
    Exit;
  targetResponses := ElementByPath(aTargetInfo, 'Responses');
  if Assigned(targetResponses) then
    Remove(targetResponses);
  Add(aTargetInfo, 'Responses', True);
  targetResponses := ElementByPath(aTargetInfo, 'Responses');
  if not Assigned(targetResponses) then
    Exit;
  row := ElementAssign(targetResponses, LowInteger,
    ElementByIndex(sourceResponses, 0), False);
  if not Assigned(row) then
    Exit;
  SetElementEditValues(row, 'NAM1', NPCResponse);
  Result := SameText(GetElementEditValues(row, 'NAM1'), NPCResponse);
end;

function AddSexLabEligibility(aInfo: IInterface): Boolean;
var
  conditions, sourceCondition, newCondition: IInterface;
begin
  Result := False;
  conditions := ElementByPath(aInfo, 'Conditions');
  if not Assigned(conditions) then
    Exit;

  sourceCondition := FindGlobalCondition(OStimInfo);
  newCondition := ElementAssign(conditions, HighInteger, sourceCondition, False);
  if not PointGlobalCondition(newCondition, SexLabGate) then
    Exit;

  sourceCondition := FindConditionByVariable(OStimInfo, FreeMaidSlotsVariable);
  if not Assigned(sourceCondition) then
    Exit;
  if not Assigned(ElementAssign(conditions, HighInteger, sourceCondition, False)) then
    Exit;

  sourceCondition := FindConditionByVariable(OStimInfo, SubjectMaidVariable);
  if not Assigned(sourceCondition) then
    Exit;
  if not Assigned(ElementAssign(conditions, HighInteger, sourceCondition, False)) then
    Exit;

  sourceCondition := FindConditionByVariable(OStimInfo, SubjectSlaveVariable);
  if not Assigned(sourceCondition) then
    Exit;
  if not Assigned(ElementAssign(conditions, HighInteger, sourceCondition, False)) then
    Exit;

  Result := ElementCount(conditions) = 10;
end;

function InstallSexLabHandler(aInfo: IInterface): Boolean;
var
  vmad: IInterface;
begin
  Result := False;
  vmad := ElementBySignature(aInfo, 'VMAD');
  if not Assigned(vmad) or not TreeHasExactValue(vmad, 'MME_Dialogues') or
     not TreeHasExactValue(vmad, 'Fragment_02') then begin
    AddMessage('ERROR: Original MME INFO VMAD was not preserved on the copy.');
    Exit;
  end;
  ReplaceTreeValue(vmad, 'MME_Dialogues', HandlerScriptName);
  ReplaceTreeValue(vmad, 'Fragment_02', HandlerFragmentName);
  Result := TreeHasExactValue(vmad, HandlerScriptName) and
    TreeHasExactValue(vmad, HandlerFragmentName) and
    not TreeHasExactValue(vmad, 'MME_Dialogues') and
    not TreeHasExactValue(vmad, 'Fragment_02');
end;

function InstallSexLabRoute: Boolean;
var
  newTopic, newInfo, topicField, previousField: IInterface;
begin
  Result := False;
  if Assigned(ExistingSexLabInfo) then begin
    Remove(ExistingSexLabInfo);
    ExistingSexLabInfo := nil;
  end;
  newTopic := ExistingSexLabTopic;
  if not Assigned(newTopic) then
    newTopic := wbCopyElementToFile(OriginalMMETopic, TargetFile, True, True);
  if not Assigned(newTopic) then
    Exit;
  SetEditorID(newTopic, SexLabTopicEditorID);
  SetElementEditValues(newTopic, 'FULL', PlayerPrompt);

  newInfo := wbCopyElementToFile(OriginalMMEInfo, TargetFile, True, True);
  if not Assigned(newInfo) then
    Exit;
  topicField := ElementByName(newInfo, 'Topic');
  if not Assigned(topicField) then begin
    Remove(newInfo);
    Exit;
  end;
  SetEditValue(topicField, Name(newTopic));
  SetEditorID(newInfo, SexLabInfoEditorID);
  SetElementEditValues(newInfo, 'RNAM', PlayerPrompt);
  previousField := ElementBySignature(newInfo, 'PNAM');
  if Assigned(previousField) then
    Remove(previousField);

  if not CopyResponseText(newInfo) or not AddSexLabEligibility(newInfo) or
     not InstallSexLabHandler(newInfo) then begin
    AddMessage('ERROR: SexLab New Milk Maid INFO configuration failed.');
    Remove(newInfo);
    Exit;
  end;
  if not EnsureChoiceLink(OpeningInfo, newTopic) then begin
    AddMessage('ERROR: Could not link the SexLab topic under Hey there.');
    Exit;
  end;
  AddMessage('SexLab topic: ' + Name(newTopic));
  AddMessage('SexLab INFO: ' + Name(newInfo));
  AddMessage('Conditions: ' + IntToStr(ElementCount(ElementByPath(newInfo,
    'Conditions'))));
  Result := True;
end;

function Initialize: Integer;
begin
  Result := 1;
  TargetFile := FindFileByName(TargetPluginName);
  MMEFile := FindFileByName(MMEPluginName);
  if not Assigned(TargetFile) or not Assigned(MMEFile) then begin
    AddMessage('ERROR: Load MilkModNEW.esp and MMEAlert.esp.');
    Exit;
  end;

  OStimTopic := FindRecordByEditorIDRecursive(GroupBySignature(TargetFile,
    'DIAL'), 'DIAL', OStimTopicEditorID);
  OStimInfo := FindRecordByEditorIDRecursive(GroupBySignature(TargetFile,
    'DIAL'), 'INFO', OStimInfoEditorID);
  OStimGate := FindRecordByEditorIDRecursive(GroupBySignature(TargetFile,
    'GLOB'), 'GLOB', OStimGateEditorID);
  SexLabGate := FindRecordByEditorIDRecursive(GroupBySignature(TargetFile,
    'GLOB'), 'GLOB', SexLabGateEditorID);
  if not Assigned(SexLabGate) then
    SexLabGate := FindRecordByEditorIDRecursive(GroupBySignature(TargetFile,
      'GLOB'), 'GLOB', OldNeutralGateEditorID);
  if not Assigned(OStimTopic) or not Assigned(OStimInfo) or
     not Assigned(OStimGate) or not Assigned(SexLabGate) then begin
    AddMessage('ERROR: Existing New Milk Maid/OStim records are incomplete.');
    Exit;
  end;

  OriginalMMETopic := FindRecordByEditorIDRecursive(
    GroupBySignature(MMEFile, 'DIAL'), 'DIAL', OriginalMMETopicEditorID);
  OriginalMMEInfo := FindOriginalSexLabInfo(
    GroupBySignature(MMEFile, 'DIAL'), OriginalMMETopic);
  if not Assigned(OriginalMMEInfo) or not Assigned(OriginalMMETopic) then begin
    AddMessage('ERROR: Original MME SexLab breastfeeding source did not resolve.');
    Exit;
  end;

  OpeningInfo := FindOpeningInfo(GroupBySignature(MMEFile, 'DIAL'));
  if not Assigned(OpeningInfo) or not EnsureOpeningOverride then begin
    AddMessage('ERROR: MME Hey there opening INFO did not resolve.');
    Exit;
  end;

  ExistingSexLabTopic := FindRecordByEditorIDRecursive(
    GroupBySignature(TargetFile, 'DIAL'), 'DIAL', SexLabTopicEditorID);
  ExistingSexLabInfo := FindRecordByEditorIDRecursive(
    GroupBySignature(TargetFile, 'DIAL'), 'INFO', SexLabInfoEditorID);

  if not RestoreOStimRouteAndGate then
    Exit;
  if not InstallSexLabRoute then
    Exit;

  AddMessage('SUCCESS: separate OStim and SexLab New Milk Maid entrances installed.');
  AddMessage('OStim keeps its existing fragment; SexLab calls original MME Fragment_02 through MMENewMilkMaid.');
  Result := 0;
end;

end.
