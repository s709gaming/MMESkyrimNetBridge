unit UserScript;

{
  Adds two optional OStim alternatives beside MME's original breastfeeding
  INFOs. The source INFOs are never overridden: their prompts, responses,
  conditions, topics, and SexLab fragments remain owned by MilkModNEW.esp.

  Required loaded files:
    MilkModNEW.esp
    MMEAlert.esp

  Safe to rerun. Existing INFOs with the two exact EditorIDs are rebuilt from
  their validated source records. Ambiguous source or target records abort the
  script before modification.
}

const
  TargetPluginName = 'MMEAlert.esp';
  MMEPluginName = 'MilkModNEW.esp';
  ControllerQuestEditorID = 'MMEAlertDebugQuest';
  HandlerScriptName = 'MMEOStimBreastfeeding';
  AvailabilityVariable = '::OStimDialogueAvailable_var';
  SexLabAnimationVariable = '::MME_BreasfeedingAnimationsCheck_var';

  PlayerDrinksEditorID = 'MMEExt_OStimBreastfeeding_PlayerDrinks';
  NPCDrinksEditorID = 'MMEExt_OStimBreastfeeding_NPCDrinks';
  PlayerDrinksSourceFragment = 'Fragment_01';
  NPCDrinksSourceFragment = 'Fragment_02';
  PlayerDrinksTargetFragment = 'Fragment_PlayerDrinks';
  NPCDrinksTargetFragment = 'Fragment_NPCDrinks';

var
  TargetFile, MMEFile, ControllerQuest: IInterface;
  PlayerDrinksSource, NPCDrinksSource: IInterface;
  PlayerDrinksSourceCount, NPCDrinksSourceCount: Integer;
  PlayerDrinksTarget, NPCDrinksTarget: IInterface;
  PlayerDrinksTargetCount, NPCDrinksTargetCount: Integer;

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

procedure FindSourcesRecursive(aElement: IInterface);
var
  i: Integer;
  vmad: IInterface;
begin
  if not Assigned(aElement) then
    Exit;
  if Signature(aElement) = 'INFO' then begin
    vmad := ElementBySignature(aElement, 'VMAD');
    if Assigned(vmad) and TreeHasExactValue(vmad, 'MME_Dialogues') then begin
      if TreeHasExactValue(vmad, PlayerDrinksSourceFragment) then begin
        Inc(PlayerDrinksSourceCount);
        PlayerDrinksSource := aElement;
      end;
      if TreeHasExactValue(vmad, NPCDrinksSourceFragment) then begin
        Inc(NPCDrinksSourceCount);
        NPCDrinksSource := aElement;
      end;
    end;
  end;
  for i := 0 to ElementCount(aElement) - 1 do
    FindSourcesRecursive(ElementByIndex(aElement, i));
end;

procedure FindTargetsRecursive(aElement: IInterface);
var
  i: Integer;
begin
  if not Assigned(aElement) then
    Exit;
  if Signature(aElement) = 'INFO' then begin
    if SameText(EditorID(aElement), PlayerDrinksEditorID) then begin
      Inc(PlayerDrinksTargetCount);
      PlayerDrinksTarget := aElement;
    end;
    if SameText(EditorID(aElement), NPCDrinksEditorID) then begin
      Inc(NPCDrinksTargetCount);
      NPCDrinksTarget := aElement;
    end;
  end;
  for i := 0 to ElementCount(aElement) - 1 do
    FindTargetsRecursive(ElementByIndex(aElement, i));
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

function UsesSameTopic(aInfo, aSourceInfo: IInterface): Boolean;
var
  infoTopic, sourceTopic: IInterface;
begin
  Result := False;
  if not Assigned(aInfo) or not Assigned(aSourceInfo) then
    Exit;
  infoTopic := LinksTo(ElementByName(aInfo, 'Topic'));
  sourceTopic := LinksTo(ElementByName(aSourceInfo, 'Topic'));
  Result := Assigned(infoTopic) and Assigned(sourceTopic) and
    Equals(MasterOrSelf(infoTopic), MasterOrSelf(sourceTopic));
end;

function ValidateSourceIsTopicTail(aSourceInfo: IInterface): Boolean;
var
  sourceTopic, topicChildren, candidate, previousElement,
    previousInfo: IInterface;
  i, infoCount: Integer;
  sourceFound: Boolean;
begin
  Result := False;
  sourceTopic := LinksTo(ElementByName(aSourceInfo, 'Topic'));
  if not Assigned(sourceTopic) then begin
    AddMessage('ERROR: Source INFO topic could not be resolved: ' +
      Name(aSourceInfo));
    Exit;
  end;
  topicChildren := ChildGroup(sourceTopic);
  if not Assigned(topicChildren) then begin
    AddMessage('ERROR: Source topic has no INFO child group: ' +
      Name(sourceTopic));
    Exit;
  end;

  infoCount := 0;
  sourceFound := False;
  previousElement := ElementBySignature(aSourceInfo, 'PNAM');
  if Assigned(previousElement) then begin
    previousInfo := LinksTo(previousElement);
    if Assigned(previousInfo) then
      AddMessage('  Source previous INFO: ' + Name(previousInfo))
    else
      AddMessage('  Source previous INFO: <none> (PNAM is null)');
  end else
    AddMessage('  Source previous INFO: <none> (PNAM is absent)');

  for i := 0 to ElementCount(topicChildren) - 1 do begin
    candidate := ElementByIndex(topicChildren, i);
    if Signature(candidate) = 'INFO' then begin
      Inc(infoCount);
      if Equals(MasterOrSelf(candidate), MasterOrSelf(aSourceInfo)) then
        sourceFound := True
      else begin
        previousElement := ElementBySignature(candidate, 'PNAM');
        if Assigned(previousElement) then begin
          previousInfo := LinksTo(previousElement);
          if Assigned(previousInfo) and
             Equals(MasterOrSelf(previousInfo),
               MasterOrSelf(aSourceInfo)) then begin
            AddMessage('ERROR: Source INFO already has a following sibling: ' +
              Name(candidate));
            AddMessage('Adding another follower would create an ambiguous INFO chain.');
            Exit;
          end;
        end;
      end;
    end;
  end;

  if not sourceFound then begin
    AddMessage('ERROR: Source INFO is not present in its resolved topic child group.');
    Exit;
  end;

  AddMessage('  Source topic INFO count: ' + IntToStr(infoCount) +
    '; source has no following sibling.');
  Result := True;
end;

function LinkAfterSource(aInfo, aSourceInfo: IInterface): Boolean;
var
  previousElement, linkedInfo: IInterface;
begin
  Result := False;
  previousElement := ElementBySignature(aInfo, 'PNAM');
  if not Assigned(previousElement) then begin
    Add(aInfo, 'PNAM', True);
    previousElement := ElementBySignature(aInfo, 'PNAM');
  end;
  if not Assigned(previousElement) then begin
    AddMessage('ERROR: Could not create the INFO PNAM subrecord.');
    Exit;
  end;

  // Name() lets xEdit translate the source INFO into the target plugin's
  // master-relative FormID namespace. Writing FormID(aSourceInfo) natively
  // would retain the source file's namespace and can leave an invalid link.
  SetEditValue(previousElement, Name(aSourceInfo));
  linkedInfo := LinksTo(previousElement);
  if not Assigned(linkedInfo) then begin
    AddMessage('ERROR: PNAM did not resolve after assignment. Value: ' +
      GetEditValue(previousElement));
    Exit;
  end;
  if not Equals(MasterOrSelf(linkedInfo), MasterOrSelf(aSourceInfo)) or
     (GetLoadOrderFormID(linkedInfo) <>
       GetLoadOrderFormID(aSourceInfo)) then begin
    AddMessage('ERROR: PNAM resolved to the wrong INFO.');
    AddMessage('  Expected: ' + Name(aSourceInfo));
    AddMessage('  Found: ' + Name(linkedInfo));
    Exit;
  end;

  AddMessage('  Previous INFO: ' + Name(linkedInfo));
  Result := True;
end;

procedure ReplaceTreeValue(aElement: IInterface; aOldValue, aNewValue: string);
var
  i: Integer;
  value: string;
begin
  if not Assigned(aElement) then
    Exit;
  value := GetEditValue(aElement);
  if SameText(value, aOldValue) then
    SetEditValue(aElement, aNewValue);
  for i := 0 to ElementCount(aElement) - 1 do
    ReplaceTreeValue(ElementByIndex(aElement, i), aOldValue, aNewValue);
end;

function RebuildConditions(aInfo, aSourceInfo: IInterface): Boolean;
var
  sourceConditions, targetConditions, templateCondition, newCondition,
    sourceCondition: IInterface;
  i, removedSexLabGate: Integer;
begin
  Result := False;
  sourceConditions := ElementByPath(aSourceInfo, 'Conditions');
  if not Assigned(sourceConditions) then begin
    AddMessage('ERROR: Source INFO has no conditions.');
    Exit;
  end;

  targetConditions := ElementByPath(aInfo, 'Conditions');
  if Assigned(targetConditions) then
    Remove(targetConditions);
  Add(aInfo, 'Conditions', True);
  targetConditions := ElementByPath(aInfo, 'Conditions');
  if not Assigned(targetConditions) then
    Exit;

  templateCondition := nil;
  removedSexLabGate := 0;
  for i := 0 to ElementCount(sourceConditions) - 1 do begin
    sourceCondition := ElementByIndex(sourceConditions, i);
    if SameText(GetElementEditValues(sourceCondition, 'CTDA\Function'),
        'GetVMQuestVariable') and
       SameText(GetElementEditValues(sourceCondition, 'CIS2'),
        SexLabAnimationVariable) then begin
      templateCondition := sourceCondition;
      Inc(removedSexLabGate);
    end else
      ElementAssign(targetConditions, HighInteger, sourceCondition, False);
  end;
  if (removedSexLabGate <> 1) or not Assigned(templateCondition) then begin
    AddMessage('ERROR: Expected exactly one SexLab-animation condition; found ' +
      IntToStr(removedSexLabGate) + '.');
    Exit;
  end;

  newCondition := ElementAssign(targetConditions, HighInteger,
    templateCondition, False);
  if not Assigned(newCondition) then
    Exit;

  SetElementNativeValues(newCondition, 'CTDA\Parameter #1',
    FormID(ControllerQuest));
  SetElementEditValues(newCondition, 'CIS2', AvailabilityVariable);

  Result := SameText(GetElementEditValues(newCondition, 'CTDA\Function'),
      'GetVMQuestVariable') and
    SameText(GetElementEditValues(newCondition, 'CIS2'), AvailabilityVariable) and
    Equals(MasterOrSelf(LinksTo(ElementByPath(newCondition,
      'CTDA\Parameter #1'))), MasterOrSelf(ControllerQuest)) and
    (ElementCount(targetConditions) = ElementCount(sourceConditions));
end;

function RebuildResponses(aInfo, aSourceInfo: IInterface): Boolean;
var
  sourceResponses, targetResponses: IInterface;
begin
  Result := False;
  sourceResponses := ElementByPath(aSourceInfo, 'Responses');
  if not Assigned(sourceResponses) or (ElementCount(sourceResponses) = 0) then
    Exit;
  targetResponses := ElementByPath(aInfo, 'Responses');
  if Assigned(targetResponses) then
    Remove(targetResponses);
  Add(aInfo, 'Responses', True);
  targetResponses := ElementByPath(aInfo, 'Responses');
  if not Assigned(targetResponses) then
    Exit;
  ElementAssign(targetResponses, LowInteger, sourceResponses, False);
  Result := ElementCount(targetResponses) = ElementCount(sourceResponses);
end;

function InstallHandler(aInfo, aSourceInfo: IInterface;
  aSourceFragment, aTargetFragment: string): Boolean;
var
  sourceVmad, targetVmad: IInterface;
begin
  Result := False;
  targetVmad := ElementBySignature(aInfo, 'VMAD');
  if Assigned(targetVmad) then
    Remove(targetVmad);
  sourceVmad := ElementBySignature(aSourceInfo, 'VMAD');
  if not Assigned(sourceVmad) then
    Exit;
  Add(aInfo, 'VMAD', True);
  targetVmad := ElementBySignature(aInfo, 'VMAD');
  if not Assigned(targetVmad) then
    Exit;
  ElementAssign(targetVmad, LowInteger, sourceVmad, False);
  ReplaceTreeValue(targetVmad, 'MME_Dialogues', HandlerScriptName);
  ReplaceTreeValue(targetVmad, aSourceFragment, aTargetFragment);
  Result := TreeHasExactValue(targetVmad, HandlerScriptName) and
    TreeHasExactValue(targetVmad, aTargetFragment) and
    not TreeHasExactValue(targetVmad, 'MME_Dialogues') and
    not TreeHasExactValue(targetVmad, aSourceFragment);
end;

function InstallRoute(aSourceInfo, aExistingInfo: IInterface;
  aEditorID, aSourceFragment, aTargetFragment: string): Boolean;
var
  newInfo: IInterface;
  prompt: string;
  createdInfo: Boolean;
begin
  Result := False;
  createdInfo := False;
  prompt := GetElementEditValues(aSourceInfo, 'RNAM');
  if prompt = '' then begin
    AddMessage('ERROR: Source INFO has an empty player prompt: ' + Name(aSourceInfo));
    Exit;
  end;

  if Assigned(aExistingInfo) then begin
    newInfo := aExistingInfo;
    AddMessage('Updating existing route: ' + Name(newInfo));
  end else begin
    AddRequiredElementMasters(aSourceInfo, TargetFile, False);
    newInfo := wbCopyElementToFile(aSourceInfo, TargetFile, True, True);
    if not Assigned(newInfo) then begin
      AddMessage('ERROR: xEdit could not copy source INFO ' + Name(aSourceInfo));
      Exit;
    end;
    createdInfo := True;
    AddMessage('Created new route from ' + Name(aSourceInfo));
  end;

  SetEditorID(newInfo, aEditorID);
  SetElementEditValues(newInfo, 'RNAM', '(OStim) ' + prompt);

  if not RebuildResponses(newInfo, aSourceInfo) or
     not RebuildConditions(newInfo, aSourceInfo) or
     not InstallHandler(newInfo, aSourceInfo, aSourceFragment,
       aTargetFragment) then begin
    AddMessage('ERROR: Failed to configure ' + aEditorID + '.');
    if createdInfo then
      Remove(newInfo);
    Exit;
  end;

  // Point this new INFO at the original as its previous sibling. The preflight
  // tail check proves this does not branch or override MME's original chain.
  if not LinkAfterSource(newInfo, aSourceInfo) then begin
    AddMessage('ERROR: Could not link ' + aEditorID + ' after its source INFO.');
    if createdInfo then
      Remove(newInfo);
    Exit;
  end;

  AddMessage('  INFO: ' + Name(newInfo));
  AddMessage('  Prompt: ' + GetElementEditValues(newInfo, 'RNAM'));
  AddMessage('  Responses preserved: ' +
    IntToStr(ElementCount(ElementByPath(newInfo, 'Responses'))));
  AddMessage('  MME conditions retained; SexLab-animation gate replaced by OStim gate: ' +
    IntToStr(ElementCount(ElementByPath(newInfo, 'Conditions'))));
  AddMessage('  Handler: ' + HandlerScriptName + '.' + aTargetFragment);
  Result := True;
end;

function Initialize: Integer;
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
      MMEPluginName + '. No records were modified.');
    Exit;
  end;

  ControllerQuest := FindRecordByEditorIDRecursive(TargetFile, 'QUST',
    ControllerQuestEditorID);
  if not Assigned(ControllerQuest) then begin
    AddMessage('ERROR: Could not find the exact controller quest ' +
      ControllerQuestEditorID + '. No records were modified.');
    Exit;
  end;

  PlayerDrinksSourceCount := 0;
  NPCDrinksSourceCount := 0;
  FindSourcesRecursive(GroupBySignature(MMEFile, 'DIAL'));
  PlayerDrinksTargetCount := 0;
  NPCDrinksTargetCount := 0;
  FindTargetsRecursive(GroupBySignature(TargetFile, 'DIAL'));

  if (PlayerDrinksSourceCount <> 1) or
     (NPCDrinksSourceCount <> 1) then begin
    AddMessage('ERROR: Expected one MME Fragment_01 and one Fragment_02 INFO; found ' +
      IntToStr(PlayerDrinksSourceCount) + ' and ' +
      IntToStr(NPCDrinksSourceCount) + '. No records were modified.');
    Exit;
  end;
  if (PlayerDrinksTargetCount > 1) or (NPCDrinksTargetCount > 1) then begin
    AddMessage('ERROR: Duplicate MME Extensions OStim EditorIDs found. No records were modified.');
    Exit;
  end;
  if Assigned(PlayerDrinksTarget) and
     not UsesSameTopic(PlayerDrinksTarget, PlayerDrinksSource) then begin
    AddMessage('ERROR: Existing ' + PlayerDrinksEditorID +
      ' is under the wrong topic. No records were modified.');
    Exit;
  end;
  if Assigned(NPCDrinksTarget) and
     not UsesSameTopic(NPCDrinksTarget, NPCDrinksSource) then begin
    AddMessage('ERROR: Existing ' + NPCDrinksEditorID +
      ' is under the wrong topic. No records were modified.');
    Exit;
  end;

  AddMessage('Validated player-drinks source: ' + Name(PlayerDrinksSource));
  AddMessage('  Prompt: ' + GetElementEditValues(PlayerDrinksSource, 'RNAM'));
  AddMessage('Validated NPC-drinks source: ' + Name(NPCDrinksSource));
  AddMessage('  Prompt: ' + GetElementEditValues(NPCDrinksSource, 'RNAM'));
  AddMessage('Original MME INFOs will not be overridden.');

  if not ValidateSourceIsTopicTail(PlayerDrinksSource) or
     not ValidateSourceIsTopicTail(NPCDrinksSource) then begin
    AddMessage('ERROR: The original INFO chain is not safe for additive insertion.');
    AddMessage('No records were modified.');
    Exit;
  end;

  if not InstallRoute(PlayerDrinksSource, PlayerDrinksTarget,
      PlayerDrinksEditorID, PlayerDrinksSourceFragment,
      PlayerDrinksTargetFragment) then
    Exit;
  if not InstallRoute(NPCDrinksSource, NPCDrinksTarget,
      NPCDrinksEditorID, NPCDrinksSourceFragment,
      NPCDrinksTargetFragment) then
    Exit;

  AddMessage('MME Extensions OStim breastfeeding dialogue installed successfully.');
  AddMessage('Both original MME/SexLab routes remain unchanged.');
  AddMessage('New routes are directly after their originals because placing them above');
  AddMessage('would require an override of the original INFO chain.');
  Result := 0;
end;

end.
