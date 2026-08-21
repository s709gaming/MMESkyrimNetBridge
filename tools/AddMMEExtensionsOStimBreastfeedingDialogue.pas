unit UserScript;

{
  Adds two optional OStim alternatives beside MME's original breastfeeding
  INFOs. The source breastfeeding INFOs are never overridden: their prompts,
  responses, conditions, topics, and SexLab fragments remain owned by
  MilkModNEW.esp. One additive override of MME's Hey there INFO appends only
  the two new DIALs to its TCLT choice list.

  Required loaded files:
    Skyrim.esm
    MilkModNEW.esp
    MMEAlert.esp

  Safe to rerun. Existing INFOs with the two exact EditorIDs are rebuilt from
  their validated source records. Ambiguous source or target records abort the
  script before modification.
}

const
  TargetPluginName = 'MMEAlert.esp';
  MMEPluginName = 'MilkModNEW.esp';
  SkyrimPluginName = 'Skyrim.esm';
  HandlerScriptName = 'MMEOStimBreastfeeding';
  AvailabilityGlobalEditorID = 'MMEExt_OStimDialogueAvailable';
  SexLabAnimationVariable = '::MME_BreasfeedingAnimationsCheck_var';

  PlayerDrinksEditorID = 'MMEExt_OStimBreastfeeding_PlayerDrinks';
  NPCDrinksEditorID = 'MMEExt_OStimBreastfeeding_NPCDrinks';
  PlayerDrinksTopicEditorID = 'MMEExt_OStimBreastfeeding_PlayerDrinksTopic';
  NPCDrinksTopicEditorID = 'MMEExt_OStimBreastfeeding_NPCDrinksTopic';
  PlayerDrinksSourceFragment = 'Fragment_01';
  NPCDrinksSourceFragment = 'Fragment_02';
  PlayerDrinksTargetFragment = 'Fragment_PlayerDrinks';
  NPCDrinksTargetFragment = 'Fragment_NPCDrinks';
  OpeningFragment = 'Fragment_00';

var
  TargetFile, MMEFile, SkyrimFile, AvailabilityGlobal: IInterface;
  PlayerDrinksSource, NPCDrinksSource: IInterface;
  OpeningSource: IInterface;
  PlayerDrinksSourceCount, NPCDrinksSourceCount: Integer;
  OpeningSourceCount: Integer;
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

function EnsureAvailabilityGlobal: Boolean;
var
  globalTemplate: IInterface;
begin
  Result := False;
  AvailabilityGlobal := MainRecordByEditorID(
    GroupBySignature(TargetFile, 'GLOB'), AvailabilityGlobalEditorID);
  if not Assigned(AvailabilityGlobal) then begin
    globalTemplate := RecordByFormID(SkyrimFile, $00000038, True);
    if not Assigned(globalTemplate) or (Signature(globalTemplate) <> 'GLOB') then begin
      AddMessage('ERROR: Skyrim GameHour GLOB template was not found.');
      Exit;
    end;
    AvailabilityGlobal := wbCopyElementToFile(globalTemplate, TargetFile,
      True, True);
    if not Assigned(AvailabilityGlobal) then begin
      AddMessage('ERROR: Could not create the OStim availability global.');
      Exit;
    end;
    AddMessage('Created availability global: ' +
      AvailabilityGlobalEditorID);
  end else
    AddMessage('Updating availability global: ' +
      AvailabilityGlobalEditorID);

  SetEditorID(AvailabilityGlobal, AvailabilityGlobalEditorID);
  SetElementNativeValues(AvailabilityGlobal, 'FLTV', 0.0);
  Result := SameText(EditorID(AvailabilityGlobal),
    AvailabilityGlobalEditorID);
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
      if TreeHasExactValue(vmad, OpeningFragment) then begin
        Inc(OpeningSourceCount);
        OpeningSource := aElement;
      end;
    end;
  end;
  for i := 0 to ElementCount(aElement) - 1 do
    FindSourcesRecursive(ElementByIndex(aElement, i));
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
      AddMessage('  Reachability link already present: ' + Name(aTopic));
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
  if Result then
    AddMessage('  Added Hey there reachability link: ' + Name(aTopic))
  else
    AddMessage('ERROR: Appended TCLT did not resolve to ' + Name(aTopic));
end;

function InstallReachability(aPlayerTopic, aNPCTopic: IInterface): Boolean;
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
  AddMessage('Updating Hey there reachability only: ' + Name(openingOverride));
  Result := EnsureChoiceLink(openingOverride, aPlayerTopic) and
    EnsureChoiceLink(openingOverride, aNPCTopic);
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

  SetElementEditValues(newCondition, 'CTDA\Function', 'GetGlobalValue');
  SetEditValue(ElementByPath(newCondition, 'CTDA\Parameter #1'),
    Name(AvailabilityGlobal));
  if Assigned(ElementBySignature(newCondition, 'CIS2')) then
    Remove(ElementBySignature(newCondition, 'CIS2'));

  Result := SameText(GetElementEditValues(newCondition, 'CTDA\Function'),
      'GetGlobalValue') and
    Equals(MasterOrSelf(LinksTo(ElementByPath(newCondition,
      'CTDA\Parameter #1'))), MasterOrSelf(AvailabilityGlobal)) and
    not Assigned(ElementBySignature(newCondition, 'CIS2')) and
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
  aTopicEditorID, aEditorID, aSourceFragment, aTargetFragment: string): Boolean;
var
  sourceTopic, existingTopic, newTopic, newInfo, topicElement,
    previousElement: IInterface;
  prompt: string;
  createdTopic: Boolean;
begin
  Result := False;
  createdTopic := False;
  prompt := GetElementEditValues(aSourceInfo, 'RNAM');
  if prompt = '' then begin
    AddMessage('ERROR: Source INFO has an empty player prompt: ' + Name(aSourceInfo));
    Exit;
  end;

  sourceTopic := LinksTo(ElementByName(aSourceInfo, 'Topic'));
  if not Assigned(sourceTopic) then begin
    AddMessage('ERROR: Source DIAL did not resolve for ' + Name(aSourceInfo));
    Exit;
  end;

  // Reuse the independent DIAL on rerun. Its stable FormID may already be in
  // the opening INFO's TCLT list. Deleting and recreating multiple DIALs in a
  // live xEdit group can invalidate that group and leave dead choice links.
  existingTopic := FindRecordByEditorIDRecursive(
    GroupBySignature(TargetFile, 'DIAL'), 'DIAL', aTopicEditorID);
  if Assigned(existingTopic) then begin
    AddMessage('Reusing independent DIAL: ' + Name(existingTopic));
    newTopic := existingTopic;
    if Assigned(aExistingInfo) then begin
      if not UsesSameTopic(aExistingInfo, aSourceInfo) then begin
        AddMessage('  Rebuilding prior independent INFO: ' + Name(aExistingInfo));
        Remove(aExistingInfo);
        aExistingInfo := nil;
      end;
    end;
    SetEditorID(newTopic, aTopicEditorID);
    if not Assigned(LinksTo(ElementBySignature(newTopic, 'QNAM'))) or
       not Assigned(LinksTo(ElementBySignature(newTopic, 'BNAM'))) or
       not Equals(MasterOrSelf(LinksTo(ElementBySignature(newTopic, 'QNAM'))),
         MasterOrSelf(LinksTo(ElementBySignature(sourceTopic, 'QNAM')))) or
       not Equals(MasterOrSelf(LinksTo(ElementBySignature(newTopic, 'BNAM'))),
         MasterOrSelf(LinksTo(ElementBySignature(sourceTopic, 'BNAM')))) then begin
      AddMessage('ERROR: Existing independent DIAL has invalid MME quest/branch links.');
      Exit;
    end;
  end;

  // Migrate the obsolete same-DIAL follower from older builder versions.
  if Assigned(aExistingInfo) then begin
    if UsesSameTopic(aExistingInfo, aSourceInfo) then begin
      AddMessage('Removing obsolete same-DIAL route: ' + Name(aExistingInfo));
      Remove(aExistingInfo);
    end;
  end;

  if not Assigned(newTopic) then begin
    AddRequiredElementMasters(sourceTopic, TargetFile, False);
    // Deep-copying the DIAL creates a genuinely independent branch topic.
    // xEdit does not copy its type-7 INFO child group.
    newTopic := wbCopyElementToFile(sourceTopic, TargetFile, True, True);
    if not Assigned(newTopic) then begin
      AddMessage('ERROR: xEdit could not create independent DIAL from ' + Name(sourceTopic));
      Exit;
    end;
    createdTopic := True;
    SetEditorID(newTopic, aTopicEditorID);
    if not Assigned(LinksTo(ElementBySignature(newTopic, 'QNAM'))) or
       not Assigned(LinksTo(ElementBySignature(newTopic, 'BNAM'))) then begin
      AddMessage('ERROR: Copied DIAL did not retain its MME quest/branch links.');
      Remove(newTopic);
      Exit;
    end;
    if not Equals(MasterOrSelf(LinksTo(ElementBySignature(newTopic, 'QNAM'))),
        MasterOrSelf(LinksTo(ElementBySignature(sourceTopic, 'QNAM')))) or
       not Equals(MasterOrSelf(LinksTo(ElementBySignature(newTopic, 'BNAM'))),
        MasterOrSelf(LinksTo(ElementBySignature(sourceTopic, 'BNAM')))) then begin
      AddMessage('ERROR: Copied DIAL points at a different quest or branch.');
      Remove(newTopic);
      Exit;
    end;
  end;
  // xEdit does not deep-copy a DIAL's type-7 INFO child group. Copy the one
  // source INFO separately, then retarget xEdit's synthetic Topic element;
  // this is the scripted equivalent of the UI's "Move to Topic" operation.
  AddRequiredElementMasters(aSourceInfo, TargetFile, False);
  newInfo := wbCopyElementToFile(aSourceInfo, TargetFile, True, True);
  if not Assigned(newInfo) then begin
    AddMessage('ERROR: xEdit could not copy source INFO ' + Name(aSourceInfo));
    if createdTopic then
      Remove(newTopic);
    Exit;
  end;
  topicElement := ElementByName(newInfo, 'Topic');
  if not Assigned(topicElement) then begin
    AddMessage('ERROR: Copied INFO exposes no xEdit Topic relationship.');
    Remove(newInfo);
    if createdTopic then
      Remove(newTopic);
    Exit;
  end;
  SetEditValue(topicElement, Name(newTopic));
  if not Assigned(LinksTo(ElementByName(newInfo, 'Topic'))) or
     not Equals(MasterOrSelf(LinksTo(ElementByName(newInfo, 'Topic'))),
       MasterOrSelf(newTopic)) then begin
    AddMessage('ERROR: xEdit could not move copied INFO into independent DIAL.');
    Remove(newInfo);
    if createdTopic then
      Remove(newTopic);
    Exit;
  end;

  SetEditorID(newInfo, aEditorID);
  SetElementEditValues(newInfo, 'RNAM', '(OStim) ' + prompt);

  if not RebuildResponses(newInfo, aSourceInfo) or
     not RebuildConditions(newInfo, aSourceInfo) or
     not InstallHandler(newInfo, aSourceInfo, aSourceFragment,
       aTargetFragment) then begin
    AddMessage('ERROR: Failed to configure ' + aEditorID + '.');
    Remove(newInfo);
    if createdTopic then
      Remove(newTopic);
    Exit;
  end;

  previousElement := ElementBySignature(newInfo, 'PNAM');
  if Assigned(previousElement) then
    Remove(previousElement);

  AddMessage('  Independent DIAL: ' + Name(newTopic));
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
  SkyrimFile := FindFileByName(SkyrimPluginName);
  if not Assigned(TargetFile) or not Assigned(MMEFile) or
     not Assigned(SkyrimFile) then begin
    AddMessage('ERROR: Load ' + SkyrimPluginName + ', ' + MMEPluginName +
      ', and ' + TargetPluginName + ' before running this script.');
    Exit;
  end;
  if GetLoadOrder(MMEFile) > GetLoadOrder(TargetFile) then begin
    AddMessage('ERROR: ' + TargetPluginName + ' must load after ' +
      MMEPluginName + '. No records were modified.');
    Exit;
  end;

  PlayerDrinksSourceCount := 0;
  NPCDrinksSourceCount := 0;
  OpeningSourceCount := 0;
  FindSourcesRecursive(GroupBySignature(MMEFile, 'DIAL'));
  PlayerDrinksTargetCount := 0;
  NPCDrinksTargetCount := 0;
  FindTargetsRecursive(GroupBySignature(TargetFile, 'DIAL'));

  if (PlayerDrinksSourceCount <> 1) or
     (NPCDrinksSourceCount <> 1) or (OpeningSourceCount <> 1) then begin
    AddMessage('ERROR: Expected one MME Fragment_00, Fragment_01, and Fragment_02 INFO; found opening=' +
      IntToStr(OpeningSourceCount) + ', routes=' +
      IntToStr(PlayerDrinksSourceCount) + ' and ' +
      IntToStr(NPCDrinksSourceCount) + '. No records were modified.');
    Exit;
  end;
  if (PlayerDrinksTargetCount > 1) or (NPCDrinksTargetCount > 1) then begin
    AddMessage('ERROR: Duplicate MME Extensions OStim EditorIDs found. No records were modified.');
    Exit;
  end;

  AddMessage('Validated player-drinks source: ' + Name(PlayerDrinksSource));
  AddMessage('  Prompt: ' + GetElementEditValues(PlayerDrinksSource, 'RNAM'));
  AddMessage('Validated NPC-drinks source: ' + Name(NPCDrinksSource));
  AddMessage('  Prompt: ' + GetElementEditValues(NPCDrinksSource, 'RNAM'));
  AddMessage('Original MME breastfeeding INFOs will not be overridden.');

  if not EnsureAvailabilityGlobal then begin
    AddMessage('ERROR: OStim availability global setup failed.');
    Exit;
  end;

  if not InstallRoute(PlayerDrinksSource, PlayerDrinksTarget,
      PlayerDrinksTopicEditorID, PlayerDrinksEditorID, PlayerDrinksSourceFragment,
      PlayerDrinksTargetFragment) then
    Exit;
  if not InstallRoute(NPCDrinksSource, NPCDrinksTarget,
      NPCDrinksTopicEditorID, NPCDrinksEditorID, NPCDrinksSourceFragment,
      NPCDrinksTargetFragment) then
    Exit;

  if not InstallReachability(
      FindRecordByEditorIDRecursive(GroupBySignature(TargetFile, 'DIAL'),
        'DIAL', PlayerDrinksTopicEditorID),
      FindRecordByEditorIDRecursive(GroupBySignature(TargetFile, 'DIAL'),
        'DIAL', NPCDrinksTopicEditorID)) then
    Exit;

  AddMessage('MME Extensions OStim breastfeeding dialogue installed successfully.');
  AddMessage('Both original MME/SexLab routes remain unchanged.');
  AddMessage('New routes are independent DIAL topics linked from MME Hey there.');
  AddMessage('Only the opening INFO TCLT choice list is additively overridden; original breastfeeding INFOs remain untouched.');
  Result := 0;
end;

end.
