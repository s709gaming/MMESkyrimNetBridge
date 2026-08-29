unit UserScript;

{
  Adds the isolated "breastfeeding creates a Milk Maid" choice under MME's
  existing Hey there dialogue. The working MME Extensions OStim NPC-drinks
  route is copied as the structural and validation source. Verified MME quest
  variable CTDAs hide it for existing Milk Maids, Milk Slaves, invalid-sex
  targets, and full Milk Maid capacity. Safe to rerun by stable EditorID.

  Required loaded files:
    Skyrim.esm
    MilkModNEW.esp
    MMEAlert.esp
}

const
  TargetPluginName = 'MMEAlert.esp';
  MMEPluginName = 'MilkModNEW.esp';

  SourceTopicEditorID = 'MMEExt_OStimBreastfeeding_NPCDrinksTopic';
  SourceInfoEditorID = 'MMEExt_OStimBreastfeeding_NPCDrinks';
  SubjectMaidGateTopicEditorID = 'MME_BreastEPotion_Topic';
  FreeMaidGateTopicEditorID = 'MME_Maid_Making_Topic';
  SubjectMaidVariable = '::MME_SubjectMaid_var';
  SubjectSlaveVariable = '::MME_SubjectSlave_var';
  FreeMaidSlotsVariable = '::MME_FreeMaidSlots_var';
  OpeningFragment = 'Fragment_00';

  TargetTopicEditorID = 'MMEExt_NewMilkMaidTopic';
  TargetInfoEditorID = 'MMEExt_NewMilkMaid';
  HandlerScriptName = 'MMENewMilkMaid';
  HandlerFragmentName = 'Fragment_CreateMilkMaid';
  PlayerPrompt = 'Wanna become a Milk Maid? Have a taste! Straight from the tap.';
  NPCResponse = 'I''d love a sip! Yummy!';

var
  TargetFile, MMEFile: IInterface;
  SourceTopic, SourceInfo, OpeningSource: IInterface;
  SubjectMaidCondition, FreeMaidSlotsCondition: IInterface;
  SourceTopicCount, SourceInfoCount, OpeningSourceCount: Integer;
  SubjectMaidConditionCount, FreeMaidSlotsConditionCount: Integer;
  ExistingTopic, ExistingInfo: IInterface;
  ExistingTopicCount, ExistingInfoCount: Integer;

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

procedure FindSourceRecords(aElement: IInterface);
var
  i: Integer;
  vmad: IInterface;
begin
  if not Assigned(aElement) then
    Exit;
  if Signature(aElement) = 'DIAL' then begin
    if SameText(EditorID(aElement), SourceTopicEditorID) then begin
      Inc(SourceTopicCount);
      SourceTopic := aElement;
    end;
  end else if Signature(aElement) = 'INFO' then begin
    if SameText(EditorID(aElement), SourceInfoEditorID) then begin
      Inc(SourceInfoCount);
      SourceInfo := aElement;
    end;
    vmad := ElementBySignature(aElement, 'VMAD');
    if Equals(GetFile(aElement), MMEFile) and Assigned(vmad) and
       TreeHasExactValue(vmad, 'MME_Dialogues') and
       TreeHasExactValue(vmad, OpeningFragment) then begin
      Inc(OpeningSourceCount);
      OpeningSource := aElement;
    end;
  end;
  for i := 0 to ElementCount(aElement) - 1 do
    FindSourceRecords(ElementByIndex(aElement, i));
end;

procedure FindExistingRecords(aElement: IInterface);
var
  i: Integer;
begin
  if not Assigned(aElement) then
    Exit;
  if Signature(aElement) = 'DIAL' then begin
    if SameText(EditorID(aElement), TargetTopicEditorID) then begin
      Inc(ExistingTopicCount);
      ExistingTopic := aElement;
    end;
  end else if Signature(aElement) = 'INFO' then begin
    if SameText(EditorID(aElement), TargetInfoEditorID) then begin
      Inc(ExistingInfoCount);
      ExistingInfo := aElement;
    end;
  end;
  for i := 0 to ElementCount(aElement) - 1 do
    FindExistingRecords(ElementByIndex(aElement, i));
end;

procedure FindSubjectMaidCondition(aElement, aGateTopic: IInterface);
var
  i, j: Integer;
  topicElement, conditions, condition: IInterface;
begin
  if not Assigned(aElement) then
    Exit;
  if Signature(aElement) = 'INFO' then begin
    topicElement := ElementByName(aElement, 'Topic');
    if Assigned(topicElement) and Assigned(LinksTo(topicElement)) and
       Equals(MasterOrSelf(LinksTo(topicElement)), MasterOrSelf(aGateTopic)) then begin
      conditions := ElementByPath(aElement, 'Conditions');
      if Assigned(conditions) then
        for j := 0 to ElementCount(conditions) - 1 do begin
          condition := ElementByIndex(conditions, j);
          if SameText(GetElementEditValues(condition, 'CTDA\Function'),
              'GetVMQuestVariable') and
             SameText(GetElementEditValues(condition, 'CIS2'),
              SubjectMaidVariable) then begin
            Inc(SubjectMaidConditionCount);
            SubjectMaidCondition := condition;
          end;
        end;
    end;
  end;
  for i := 0 to ElementCount(aElement) - 1 do
    FindSubjectMaidCondition(ElementByIndex(aElement, i), aGateTopic);
end;

procedure FindFreeMaidSlotsCondition(aElement, aGateTopic: IInterface);
var
  i, j: Integer;
  topicElement, conditions, condition: IInterface;
begin
  if not Assigned(aElement) then
    Exit;
  if Signature(aElement) = 'INFO' then begin
    topicElement := ElementByName(aElement, 'Topic');
    if Assigned(topicElement) and Assigned(LinksTo(topicElement)) and
       Equals(MasterOrSelf(LinksTo(topicElement)), MasterOrSelf(aGateTopic)) then begin
      conditions := ElementByPath(aElement, 'Conditions');
      if Assigned(conditions) then
        for j := 0 to ElementCount(conditions) - 1 do begin
          condition := ElementByIndex(conditions, j);
          if SameText(GetElementEditValues(condition, 'CTDA\Function'),
              'GetVMQuestVariable') and
             SameText(GetElementEditValues(condition, 'CIS2'),
              FreeMaidSlotsVariable) and
             (GetElementNativeValues(condition,
              'CTDA\Comparison Value - Float') = 0.0) then begin
            Inc(FreeMaidSlotsConditionCount);
            FreeMaidSlotsCondition := condition;
          end;
        end;
    end;
  end;
  for i := 0 to ElementCount(aElement) - 1 do
    FindFreeMaidSlotsCondition(ElementByIndex(aElement, i), aGateTopic);
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

function EnsureChoiceLink(aOpeningInfo, aTopic: IInterface): Boolean;
var
  links, linkElement, template: IInterface;
  i: Integer;
begin
  Result := False;
  links := ElementByName(aOpeningInfo, 'Link To');
  if not Assigned(links) or (ElementCount(links) = 0) then begin
    AddMessage('ERROR: Hey there INFO exposes no TCLT Link To array.');
    Exit;
  end;
  for i := 0 to ElementCount(links) - 1 do begin
    linkElement := ElementByIndex(links, i);
    if Assigned(LinksTo(linkElement)) and
       Equals(MasterOrSelf(LinksTo(linkElement)), MasterOrSelf(aTopic)) then begin
      AddMessage('Reachability link already present: ' + Name(aTopic));
      Result := True;
      Exit;
    end;
  end;
  template := ElementByIndex(links, ElementCount(links) - 1);
  linkElement := ElementAssign(links, HighInteger, template, False);
  if not Assigned(linkElement) then begin
    AddMessage('ERROR: Could not append Hey there TCLT choice.');
    Exit;
  end;
  SetEditValue(linkElement, Name(aTopic));
  Result := Assigned(LinksTo(linkElement)) and
    Equals(MasterOrSelf(LinksTo(linkElement)), MasterOrSelf(aTopic));
end;

function InstallReachability(aTopic: IInterface): Boolean;
var
  winningOpening, openingOverride: IInterface;
begin
  Result := False;
  winningOpening := WinningOverride(OpeningSource);
  if Assigned(winningOpening) and Equals(GetFile(winningOpening), TargetFile) then
    openingOverride := winningOpening
  else begin
    AddRequiredElementMasters(winningOpening, TargetFile, False);
    openingOverride := wbCopyElementToFile(winningOpening, TargetFile, False, True);
  end;
  if not Assigned(openingOverride) then begin
    AddMessage('ERROR: Could not create additive Hey there INFO override.');
    Exit;
  end;
  Result := EnsureChoiceLink(openingOverride, aTopic);
end;

function RebuildResponses(aInfo: IInterface): Boolean;
var
  sourceResponses, targetResponses, response: IInterface;
begin
  Result := False;
  sourceResponses := ElementByPath(SourceInfo, 'Responses');
  if not Assigned(sourceResponses) or (ElementCount(sourceResponses) <> 1) then begin
    AddMessage('ERROR: Expected exactly one response row on OStim source INFO.');
    Exit;
  end;
  targetResponses := ElementByPath(aInfo, 'Responses');
  if Assigned(targetResponses) then
    Remove(targetResponses);
  Add(aInfo, 'Responses', True);
  targetResponses := ElementByPath(aInfo, 'Responses');
  if not Assigned(targetResponses) then
    Exit;
  response := ElementAssign(targetResponses, LowInteger,
    ElementByIndex(sourceResponses, 0), False);
  if not Assigned(response) then
    Exit;
  SetElementEditValues(response, 'NAM1', NPCResponse);
  Result := SameText(GetElementEditValues(response, 'NAM1'), NPCResponse);
end;

function RebuildConditions(aInfo: IInterface): Boolean;
var
  sourceConditions, targetConditions, sourceCondition,
    newMaidCondition, newSlaveCondition, newFreeCondition: IInterface;
  i: Integer;
begin
  Result := False;
  sourceConditions := ElementByPath(SourceInfo, 'Conditions');
  if not Assigned(sourceConditions) or (ElementCount(sourceConditions) = 0) then begin
    AddMessage('ERROR: OStim source INFO has no conditions.');
    Exit;
  end;
  targetConditions := ElementByPath(aInfo, 'Conditions');
  if Assigned(targetConditions) then
    Remove(targetConditions);
  Add(aInfo, 'Conditions', True);
  targetConditions := ElementByPath(aInfo, 'Conditions');
  if not Assigned(targetConditions) then
    Exit;

  for i := 0 to ElementCount(sourceConditions) - 1 do begin
    sourceCondition := ElementByIndex(sourceConditions, i);
    if SameText(GetElementEditValues(sourceCondition, 'CIS2'), SubjectMaidVariable) or
       SameText(GetElementEditValues(sourceCondition, 'CIS2'), SubjectSlaveVariable) or
       SameText(GetElementEditValues(sourceCondition, 'CIS2'), FreeMaidSlotsVariable) then begin
      AddMessage('ERROR: OStim source unexpectedly already has a Milk Maid eligibility condition.');
      Exit;
    end;
    ElementAssign(targetConditions, HighInteger, sourceCondition, False);
  end;

  newFreeCondition := ElementAssign(targetConditions, HighInteger,
    FreeMaidSlotsCondition, False);
  if not Assigned(newFreeCondition) then
    Exit;

  newMaidCondition := ElementAssign(targetConditions, HighInteger,
    SubjectMaidCondition, False);
  if not Assigned(newMaidCondition) then
    Exit;
  SetElementNativeValues(newMaidCondition, 'CTDA\Comparison Value - Float', 0.0);

  newSlaveCondition := ElementAssign(targetConditions, HighInteger,
    SubjectMaidCondition, False);
  if not Assigned(newSlaveCondition) then
    Exit;
  SetElementEditValues(newSlaveCondition, 'CIS2', SubjectSlaveVariable);
  SetElementNativeValues(newSlaveCondition, 'CTDA\Comparison Value - Float', 0.0);

  Result := SameText(GetElementEditValues(newFreeCondition, 'CTDA\Function'),
      'GetVMQuestVariable') and
    SameText(GetElementEditValues(newFreeCondition, 'CIS2'),
      FreeMaidSlotsVariable) and
    (GetElementNativeValues(newFreeCondition,
      'CTDA\Comparison Value - Float') = 0.0) and
    SameText(GetElementEditValues(newMaidCondition, 'CTDA\Function'),
      'GetVMQuestVariable') and
    SameText(GetElementEditValues(newMaidCondition, 'CIS2'),
      SubjectMaidVariable) and
    (GetElementNativeValues(newMaidCondition,
      'CTDA\Comparison Value - Float') = 0.0) and
    SameText(GetElementEditValues(newSlaveCondition, 'CTDA\Function'),
      'GetVMQuestVariable') and
    SameText(GetElementEditValues(newSlaveCondition, 'CIS2'),
      SubjectSlaveVariable) and
    (GetElementNativeValues(newSlaveCondition,
      'CTDA\Comparison Value - Float') = 0.0) and
    (ElementCount(targetConditions) = ElementCount(sourceConditions) + 3);
end;

function InstallHandler(aInfo: IInterface): Boolean;
var
  sourceVmad, targetVmad: IInterface;
begin
  Result := False;
  targetVmad := ElementBySignature(aInfo, 'VMAD');
  if Assigned(targetVmad) then
    Remove(targetVmad);
  sourceVmad := ElementBySignature(SourceInfo, 'VMAD');
  if not Assigned(sourceVmad) then begin
    AddMessage('ERROR: OStim source INFO has no VMAD.');
    Exit;
  end;
  Add(aInfo, 'VMAD', True);
  targetVmad := ElementBySignature(aInfo, 'VMAD');
  if not Assigned(targetVmad) then
    Exit;
  ElementAssign(targetVmad, LowInteger, sourceVmad, False);
  ReplaceTreeValue(targetVmad, 'MMEOStimBreastfeeding', HandlerScriptName);
  ReplaceTreeValue(targetVmad, 'Fragment_NPCDrinks', HandlerFragmentName);
  Result := TreeHasExactValue(targetVmad, HandlerScriptName) and
    TreeHasExactValue(targetVmad, HandlerFragmentName) and
    not TreeHasExactValue(targetVmad, 'MMEOStimBreastfeeding') and
    not TreeHasExactValue(targetVmad, 'Fragment_NPCDrinks');
end;

function InstallRoute: Boolean;
var
  newTopic, newInfo, topicElement, previousElement: IInterface;
  createdTopic: Boolean;
begin
  Result := False;
  createdTopic := False;
  newTopic := ExistingTopic;

  if Assigned(ExistingInfo) then begin
    AddMessage('Rebuilding existing INFO: ' + Name(ExistingInfo));
    Remove(ExistingInfo);
    ExistingInfo := nil;
  end;

  if not Assigned(newTopic) then begin
    newTopic := wbCopyElementToFile(SourceTopic, TargetFile, True, True);
    if not Assigned(newTopic) then begin
      AddMessage('ERROR: Could not create independent dialogue topic.');
      Exit;
    end;
    createdTopic := True;
  end;
  SetEditorID(newTopic, TargetTopicEditorID);
  SetElementEditValues(newTopic, 'FULL', PlayerPrompt);

  newInfo := wbCopyElementToFile(SourceInfo, TargetFile, True, True);
  if not Assigned(newInfo) then begin
    AddMessage('ERROR: Could not copy the OStim source INFO.');
    if createdTopic then
      Remove(newTopic);
    Exit;
  end;
  topicElement := ElementByName(newInfo, 'Topic');
  if not Assigned(topicElement) then begin
    AddMessage('ERROR: Copied INFO exposes no Topic relationship.');
    Remove(newInfo);
    if createdTopic then
      Remove(newTopic);
    Exit;
  end;
  SetEditValue(topicElement, Name(newTopic));
  if not Assigned(LinksTo(topicElement)) or
     not Equals(MasterOrSelf(LinksTo(topicElement)), MasterOrSelf(newTopic)) then begin
    AddMessage('ERROR: Copied INFO could not be moved to the new topic.');
    Remove(newInfo);
    if createdTopic then
      Remove(newTopic);
    Exit;
  end;

  SetEditorID(newInfo, TargetInfoEditorID);
  SetElementEditValues(newInfo, 'RNAM', PlayerPrompt);
  previousElement := ElementBySignature(newInfo, 'PNAM');
  if Assigned(previousElement) then
    Remove(previousElement);

  if not RebuildResponses(newInfo) or not RebuildConditions(newInfo) or
     not InstallHandler(newInfo) then begin
    AddMessage('ERROR: Failed to configure new Milk Maid INFO.');
    Remove(newInfo);
    if createdTopic then
      Remove(newTopic);
    Exit;
  end;

  if not SameText(GetElementEditValues(newInfo, 'RNAM'), PlayerPrompt) then begin
    AddMessage('ERROR: Final player prompt did not verify.');
    Exit;
  end;
  AddMessage('Topic: ' + Name(newTopic));
  AddMessage('INFO: ' + Name(newInfo));
  AddMessage('Player: ' + GetElementEditValues(newInfo, 'RNAM'));
  AddMessage('NPC: ' + GetElementEditValues(
    ElementByIndex(ElementByPath(newInfo, 'Responses'), 0), 'NAM1'));
  AddMessage('Conditions: ' + IntToStr(
    ElementCount(ElementByPath(newInfo, 'Conditions'))));
  Result := InstallReachability(newTopic);
end;

function Initialize: Integer;
var
  subjectGateTopic, freeGateTopic: IInterface;
begin
  Result := 1;
  TargetFile := FindFileByName(TargetPluginName);
  MMEFile := FindFileByName(MMEPluginName);
  if not Assigned(TargetFile) or not Assigned(MMEFile) then begin
    AddMessage('ERROR: Load ' + MMEPluginName + ' and ' +
      TargetPluginName + ' before running this script.');
    Exit;
  end;
  if GetLoadOrder(MMEFile) > GetLoadOrder(TargetFile) then begin
    AddMessage('ERROR: ' + TargetPluginName + ' must load after ' +
      MMEPluginName + '.');
    Exit;
  end;

  SourceTopicCount := 0;
  SourceInfoCount := 0;
  OpeningSourceCount := 0;
  FindSourceRecords(GroupBySignature(TargetFile, 'DIAL'));
  FindSourceRecords(GroupBySignature(MMEFile, 'DIAL'));
  if (SourceTopicCount <> 1) or (SourceInfoCount <> 1) or
     (OpeningSourceCount <> 1) then begin
    AddMessage('ERROR: Expected one source DIAL, source INFO, and MME Hey there INFO; found topic=' +
      IntToStr(SourceTopicCount) + ', info=' + IntToStr(SourceInfoCount) +
      ', opening=' + IntToStr(OpeningSourceCount) + '.');
    Exit;
  end;

  subjectGateTopic := FindRecordByEditorIDRecursive(
    GroupBySignature(MMEFile, 'DIAL'), 'DIAL',
    SubjectMaidGateTopicEditorID);
  if not Assigned(subjectGateTopic) then begin
    AddMessage('ERROR: Verified MME SubjectMaid gate topic was not found.');
    Exit;
  end;
  SubjectMaidConditionCount := 0;
  FindSubjectMaidCondition(GroupBySignature(MMEFile, 'DIAL'),
    subjectGateTopic);
  if SubjectMaidConditionCount <> 1 then begin
    AddMessage('ERROR: Expected exactly one verified SubjectMaid condition; found ' +
      IntToStr(SubjectMaidConditionCount) + '.');
    Exit;
  end;

  freeGateTopic := FindRecordByEditorIDRecursive(
    GroupBySignature(MMEFile, 'DIAL'), 'DIAL',
    FreeMaidGateTopicEditorID);
  if not Assigned(freeGateTopic) then begin
    AddMessage('ERROR: Verified MME FreeMaidSlots gate topic was not found.');
    Exit;
  end;
  FreeMaidSlotsConditionCount := 0;
  FindFreeMaidSlotsCondition(GroupBySignature(MMEFile, 'DIAL'),
    freeGateTopic);
  if FreeMaidSlotsConditionCount <> 1 then begin
    AddMessage('ERROR: Expected exactly one verified FreeMaidSlots condition; found ' +
      IntToStr(FreeMaidSlotsConditionCount) + '.');
    Exit;
  end;

  ExistingTopicCount := 0;
  ExistingInfoCount := 0;
  FindExistingRecords(GroupBySignature(TargetFile, 'DIAL'));
  if (ExistingTopicCount > 1) or (ExistingInfoCount > 1) then begin
    AddMessage('ERROR: Duplicate generated EditorIDs found; no changes made.');
    Exit;
  end;

  if not InstallRoute then
    Exit;

  AddMessage('MME Extensions breastfeeding-to-Milk-Maid dialogue installed successfully.');
  AddMessage('The ordinary OStim/SexLab breastfeeding routes remain unchanged.');
  AddMessage('The new route requires free capacity and false SubjectMaid/SubjectSlave, then revalidates at runtime.');
  Result := 0;
end;

end.
