unit UserScript;

{
  Adds two state-exclusive Mage Parasite Armor choices under MME's existing
  [MME] Hey there! opening. Safe to rerun by stable EditorID.

  IMPORTANT: this script is intentionally not automatic. With Vortex deployed,
  load Skyrim.esm, MilkModNEW.esp, MMEAlert.esp, and every plugin touching the
  MME Hey there DIAL/INFO. MMEAlert.esp must be the winning override.

  The installer refuses to mutate records when an earlier override contributes
  a DIAL response or INFO Link To entry absent from the current winner. It
  preserves the winning opening INFO's complete VMAD, changes only the original
  MME script/fragment names, and appends one bound Global property.
}

const
  TargetPluginName = 'MMEAlert.esp';
  MMEPluginName = 'MilkModNEW.esp';
  SkyrimPluginName = 'Skyrim.esm';

  OpeningTopicEditorID = 'MME_Hello_Dialogue_Topic';
  MMETradeInnTopicEditorID = 'MME_Trade_Inn_Topic';
  JobCourtWizardFactionEditorID = 'JobCourtWizardFaction';
  JobMerchantFactionEditorID = 'JobMerchantFaction';

  SourceTopicEditorID = 'MMEExt_NewMilkMaidTopic';
  SourceInfoEditorID = 'MMEExt_NewMilkMaid';
  { This existing float Global is only a structural GLOB template. Its value
    and EditorID are never reused; the copy becomes the independent state. }
  SourceGlobalEditorID = 'MMEExt_OStimDialogueAvailable';

  StateGlobalEditorID = 'MMEExt_MageParasiteArmorState';
  AddTopicEditorID = 'MMEExt_MageAddParasiteArmorTopic';
  AddInfoEditorID = 'MMEExt_MageAddParasiteArmor';
  RemoveTopicEditorID = 'MMEExt_MageRemoveParasiteArmorTopic';
  RemoveInfoEditorID = 'MMEExt_MageRemoveParasiteArmor';

  HandlerScriptName = 'MMEBlacksmithDialogue';
  StatePropertyName = 'MMEExt_MageParasiteArmorState';
  RefreshFragmentName = 'Fragment_RefreshBlacksmithArmorState';
  AddFragmentName = 'Fragment_AddParasiteArmor';
  RemoveFragmentName = 'Fragment_RemoveParasiteArmor';

  AddPrompt = 'Can you conjure some kinky tentacles under my armor?';
  AddResponse = 'My kind of woman! I know just the thing. It''ll wrap around you very nicely.';
  RemovePrompt = 'Can you give these kinky tentacles under my armor a new home?';
  RemoveResponse = 'Of course. I''ll save them for the next gal who might appreciate them.';

var
  TargetFile, MMEFile, SkyrimFile: IInterface;
  OpeningTopicMaster, OpeningInfoMaster, OpeningTopic, OpeningInfo: IInterface;
  SourceTopic, SourceInfo, SourceGlobal, StateGlobal: IInterface;
  JobCourtWizardFaction, JobMerchantFaction: IInterface;
  CourtWizardCondition, MerchantCondition: IInterface;
  GlobalCondition, ObjectPropertyTemplate: IInterface;
  OpeningInfoCandidate: IInterface;
  OpeningInfoCandidateCount: Integer;

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

function CountRecordsByEditorID(aElement: IInterface;
  aSignature, aEditorID: string): Integer;
var
  i: Integer;
begin
  Result := 0;
  if not Assigned(aElement) then
    Exit;
  if (Signature(aElement) = aSignature) and
     SameText(EditorID(aElement), aEditorID) then
    Inc(Result);
  for i := 0 to ElementCount(aElement) - 1 do
    Result := Result + CountRecordsByEditorID(ElementByIndex(aElement, i),
      aSignature, aEditorID);
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

procedure FindOpeningInfo(aTopic: IInterface);
var
  i: Integer;
  infos, candidate, vmad: IInterface;
begin
  if not Assigned(aTopic) then
    Exit;
  infos := ChildGroup(aTopic);
  if not Assigned(infos) then
    Exit;
  for i := 0 to ElementCount(infos) - 1 do begin
    candidate := ElementByIndex(infos, i);
    if Signature(candidate) <> 'INFO' then
      Continue;
    vmad := ElementBySignature(candidate, 'VMAD');
    if Assigned(vmad) and TreeHasExactValue(vmad, 'MME_Dialogues') and
       TreeHasExactValue(vmad, 'Fragment_00') then begin
      Inc(OpeningInfoCandidateCount);
      OpeningInfoCandidate := candidate;
    end;
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

function CollectionContainsLink(aCollection, aTarget: IInterface): Boolean;
var
  i: Integer;
  linked: IInterface;
begin
  Result := False;
  if not Assigned(aCollection) or not Assigned(aTarget) then
    Exit;
  for i := 0 to ElementCount(aCollection) - 1 do begin
    linked := LinksTo(ElementByIndex(aCollection, i));
    if Assigned(linked) and
       Equals(MasterOrSelf(linked), MasterOrSelf(aTarget)) then begin
      Result := True;
      Exit;
    end;
  end;
end;

function AuditCollection(aCandidate, aWinner: IInterface;
  aPath, aLabel: string): Boolean;
var
  candidateItems, winnerItems, linked: IInterface;
  i: Integer;
begin
  Result := False;
  candidateItems := ElementByPath(aCandidate, aPath);
  winnerItems := ElementByPath(aWinner, aPath);
  if not Assigned(candidateItems) then begin
    Result := True;
    Exit;
  end;
  for i := 0 to ElementCount(candidateItems) - 1 do begin
    linked := LinksTo(ElementByIndex(candidateItems, i));
    if Assigned(linked) and not CollectionContainsLink(winnerItems, linked) then begin
      AddMessage('ERROR: ' + aLabel + ' from ' +
        GetFileName(GetFile(aCandidate)) + ' is absent from the winner: ' +
        Name(linked));
      AddMessage('Resolve the dialogue conflict manually before rerunning. No records were modified.');
      Exit;
    end;
  end;
  Result := True;
end;

function AuditOverrides(aMaster, aWinner: IInterface;
  aPath, aLabel: string): Boolean;
var
  i: Integer;
  candidate: IInterface;
begin
  Result := False;
  if not AuditCollection(aMaster, aWinner, aPath, aLabel) then
    Exit;
  for i := 0 to OverrideCount(aMaster) - 1 do begin
    candidate := OverrideByIndex(aMaster, i);
    if Assigned(candidate) and not Equals(candidate, aWinner) then
      if not AuditCollection(candidate, aWinner, aPath, aLabel) then
        Exit;
  end;
  Result := True;
end;

function ChildGroupContainsRecord(aGroup, aTarget: IInterface): Boolean;
var
  i: Integer;
  candidate: IInterface;
begin
  Result := False;
  if not Assigned(aGroup) or not Assigned(aTarget) then
    Exit;
  for i := 0 to ElementCount(aGroup) - 1 do begin
    candidate := ElementByIndex(aGroup, i);
    if (Signature(candidate) = Signature(aTarget)) and
       Equals(MasterOrSelf(candidate), MasterOrSelf(aTarget)) then begin
      Result := True;
      Exit;
    end;
  end;
end;

function AuditTopicInfos(aCandidate, aWinner: IInterface): Boolean;
var
  candidateGroup, winnerGroup, candidateInfo: IInterface;
  i: Integer;
begin
  Result := False;
  candidateGroup := ChildGroup(aCandidate);
  winnerGroup := ChildGroup(aWinner);
  if not Assigned(candidateGroup) then begin
    Result := True;
    Exit;
  end;
  for i := 0 to ElementCount(candidateGroup) - 1 do begin
    candidateInfo := ElementByIndex(candidateGroup, i);
    if (Signature(candidateInfo) = 'INFO') and
       not ChildGroupContainsRecord(winnerGroup, candidateInfo) then begin
      AddMessage('ERROR: opening DIAL INFO from ' +
        GetFileName(GetFile(aCandidate)) + ' is absent from the winner: ' +
        Name(candidateInfo));
      AddMessage('Resolve the dialogue conflict manually before rerunning. No records were modified.');
      Exit;
    end;
  end;
  Result := True;
end;

function AuditTopicOverrides(aMaster, aWinner: IInterface): Boolean;
var
  i: Integer;
  candidate: IInterface;
begin
  Result := False;
  if not AuditTopicInfos(aMaster, aWinner) then
    Exit;
  for i := 0 to OverrideCount(aMaster) - 1 do begin
    candidate := OverrideByIndex(aMaster, i);
    if Assigned(candidate) and not Equals(candidate, aWinner) then
      if not AuditTopicInfos(candidate, aWinner) then
        Exit;
  end;
  Result := True;
end;

function IsObjectProperty(aElement: IInterface): Boolean;
begin
  Result := Assigned(ElementByName(aElement, 'propertyName')) and
    Assigned(ElementByPath(aElement,
      'Value\Object Union\Object v2\FormID'));
end;

function FindObjectPropTemplate(aElement: IInterface): IInterface;
var
  i: Integer;
begin
  Result := nil;
  if not Assigned(aElement) then
    Exit;
  if IsObjectProperty(aElement) then begin
    Result := aElement;
    Exit;
  end;
  for i := 0 to ElementCount(aElement) - 1 do begin
    Result := FindObjectPropTemplate(ElementByIndex(aElement, i));
    if Assigned(Result) then
      Exit;
  end;
end;

procedure FindConditionTemplates(aElement: IInterface);
var
  i, j: Integer;
  conditions, condition, parameter, linked: IInterface;
  functionName, runOn: string;
  comparison: Double;
begin
  if not Assigned(aElement) then
    Exit;
  if Assigned(CourtWizardCondition) and Assigned(MerchantCondition) and
     Assigned(GlobalCondition) then
    Exit;
  if Signature(aElement) = 'INFO' then begin
    conditions := ElementByPath(aElement, 'Conditions');
    if Assigned(conditions) then
      for j := 0 to ElementCount(conditions) - 1 do begin
        condition := ElementByIndex(conditions, j);
        functionName := GetElementEditValues(condition, 'CTDA\Function');
        runOn := GetElementEditValues(condition, 'CTDA\Run On');
        comparison := GetElementNativeValues(condition,
          'CTDA\Comparison Value - Float');
        parameter := ElementByPath(condition, 'CTDA\Parameter #1');
        linked := nil;
        if Assigned(parameter) then
          linked := LinksTo(parameter);

        if SameText(functionName, 'GetInFaction') and
           SameText(runOn, 'Subject') and (comparison = 1.0) and
           Assigned(linked) then begin
          if Equals(MasterOrSelf(linked),
              MasterOrSelf(JobCourtWizardFaction)) then begin
            if not Assigned(CourtWizardCondition) then
              CourtWizardCondition := condition;
          end
          else if Equals(MasterOrSelf(linked),
              MasterOrSelf(JobMerchantFaction)) then begin
            if not Assigned(MerchantCondition) then
              MerchantCondition := condition;
          end;
        end else if SameText(functionName, 'GetGlobalValue') and
            (comparison = 1.0) then
          GlobalCondition := condition;
      end;
  end;
  for i := 0 to ElementCount(aElement) - 1 do begin
    FindConditionTemplates(ElementByIndex(aElement, i));
    if Assigned(CourtWizardCondition) and Assigned(MerchantCondition) and
       Assigned(GlobalCondition) then
      Exit;
  end;
end;

function EnsureStateGlobal: Boolean;
begin
  Result := False;
  StateGlobal := FindRecordByEditorIDRecursive(
    GroupBySignature(TargetFile, 'GLOB'), 'GLOB', StateGlobalEditorID);
  if Assigned(StateGlobal) then begin
    SetElementNativeValues(StateGlobal, 'FLTV', 0.0);
    Result := True;
    Exit;
  end;
  StateGlobal := wbCopyElementToFile(SourceGlobal, TargetFile, True, True);
  if not Assigned(StateGlobal) then begin
    AddMessage('ERROR: Could not create the Mage state Global.');
    Exit;
  end;
  SetEditorID(StateGlobal, StateGlobalEditorID);
  SetElementNativeValues(StateGlobal, 'FLTV', 0.0);
  Result := SameText(EditorID(StateGlobal), StateGlobalEditorID);
end;

function FindScriptEntry(aVmad: IInterface; aScriptName: string): IInterface;
var
  scripts, candidate: IInterface;
  i: Integer;
begin
  Result := nil;
  scripts := ElementByPath(aVmad, 'Scripts');
  if not Assigned(scripts) then
    Exit;
  for i := 0 to ElementCount(scripts) - 1 do begin
    candidate := ElementByIndex(scripts, i);
    if SameText(GetElementEditValues(candidate, 'ScriptName'),
        aScriptName) then begin
      Result := candidate;
      Exit;
    end;
  end;
end;

function EnsureStateProperty(aVmad: IInterface): Boolean;
var
  scriptEntry, properties, propertyEntry, formField: IInterface;
  i: Integer;
begin
  Result := False;
  scriptEntry := FindScriptEntry(aVmad, HandlerScriptName);
  if not Assigned(scriptEntry) then begin
    AddMessage('ERROR: Wrapper VMAD exposes no ' + HandlerScriptName +
      ' script entry.');
    Exit;
  end;
  properties := ElementByPath(scriptEntry, 'Properties');
  if Assigned(properties) then
    for i := 0 to ElementCount(properties) - 1 do begin
      propertyEntry := ElementByIndex(properties, i);
      if SameText(GetElementEditValues(propertyEntry, 'propertyName'),
          StatePropertyName) then begin
        formField := ElementByPath(propertyEntry,
          'Value\Object Union\Object v2\FormID');
        SetEditValue(formField, Name(StateGlobal));
        Result := Assigned(LinksTo(formField)) and
          Equals(MasterOrSelf(LinksTo(formField)),
            MasterOrSelf(StateGlobal));
        Exit;
      end;
    end;

  if not Assigned(properties) then begin
    Add(scriptEntry, 'Properties', True);
    properties := ElementByPath(scriptEntry, 'Properties');
  end;
  if not Assigned(properties) or not Assigned(ObjectPropertyTemplate) then begin
    AddMessage('ERROR: Could not create a VMAD object property.');
    Exit;
  end;
  propertyEntry := ElementAssign(properties, HighInteger,
    ObjectPropertyTemplate, False);
  if not Assigned(propertyEntry) then
    Exit;
  SetElementEditValues(propertyEntry, 'propertyName', StatePropertyName);
  SetElementEditValues(propertyEntry, 'Type', 'Object');
  formField := ElementByPath(propertyEntry,
    'Value\Object Union\Object v2\FormID');
  SetEditValue(formField, Name(StateGlobal));
  SetElementNativeValues(propertyEntry,
    'Value\Object Union\Object v2\Alias', -1);
  Result := Assigned(LinksTo(formField)) and
    Equals(MasterOrSelf(LinksTo(formField)), MasterOrSelf(StateGlobal));
end;

function InstallOpeningWrapper: Boolean;
var
  vmad: IInterface;
begin
  Result := False;
  vmad := ElementBySignature(OpeningInfo, 'VMAD');
  if not Assigned(vmad) then begin
    AddMessage('ERROR: Winning MME opening INFO has no VMAD.');
    Exit;
  end;
  if TreeHasExactValue(vmad, 'MME_Dialogues') then
    ReplaceTreeValue(vmad, 'MME_Dialogues', HandlerScriptName)
  else if not TreeHasExactValue(vmad, HandlerScriptName) then begin
    AddMessage('ERROR: Opening VMAD is neither the original MME handler nor the installed wrapper.');
    Exit;
  end;
  if TreeHasExactValue(vmad, 'Fragment_00') then
    ReplaceTreeValue(vmad, 'Fragment_00', RefreshFragmentName)
  else if not TreeHasExactValue(vmad, RefreshFragmentName) then begin
    AddMessage('ERROR: Opening VMAD has an unexpected fragment binding.');
    Exit;
  end;
  if not EnsureStateProperty(vmad) then
    Exit;
  Result := TreeHasExactValue(vmad, HandlerScriptName) and
    TreeHasExactValue(vmad, RefreshFragmentName) and
    not TreeHasExactValue(vmad, 'MME_Dialogues') and
    not TreeHasExactValue(vmad, 'Fragment_00');
end;

function EnsureTopic(aEditorID, aName: string): IInterface;
var
  count: Integer;
begin
  Result := nil;
  count := CountRecordsByEditorID(GroupBySignature(TargetFile, 'DIAL'),
    'DIAL', aEditorID);
  if count > 1 then begin
    AddMessage('ERROR: Duplicate DIAL EditorID ' + aEditorID + '.');
    Exit;
  end;
  if count = 1 then
    Result := FindRecordByEditorIDRecursive(GroupBySignature(TargetFile,
      'DIAL'), 'DIAL', aEditorID)
  else
    Result := wbCopyElementToFile(SourceTopic, TargetFile, True, True);
  if not Assigned(Result) then
    Exit;
  SetEditorID(Result, aEditorID);
  SetElementEditValues(Result, 'FULL', aName);
end;

function ValidateTopicWiring(aTopic: IInterface): Boolean;
var
  sourceQuest, sourceBranch, targetQuest, targetBranch: IInterface;
begin
  Result := False;
  sourceQuest := LinksTo(ElementBySignature(SourceTopic, 'QNAM'));
  sourceBranch := LinksTo(ElementBySignature(SourceTopic, 'BNAM'));
  targetQuest := LinksTo(ElementBySignature(aTopic, 'QNAM'));
  targetBranch := LinksTo(ElementBySignature(aTopic, 'BNAM'));
  Result := Assigned(sourceQuest) and Assigned(sourceBranch) and
    Assigned(targetQuest) and Assigned(targetBranch) and
    Equals(MasterOrSelf(sourceQuest), MasterOrSelf(targetQuest)) and
    Equals(MasterOrSelf(sourceBranch), MasterOrSelf(targetBranch));
end;

procedure RemoveUnexpectedInfos(aTopic: IInterface; aExpectedEditorID: string);
var
  children, child: IInterface;
  i: Integer;
begin
  children := ChildGroup(aTopic);
  if not Assigned(children) then
    Exit;
  for i := ElementCount(children) - 1 downto 0 do begin
    child := ElementByIndex(children, i);
    if (Signature(child) = 'INFO') and
       not SameText(EditorID(child), aExpectedEditorID) then
      Remove(child);
  end;
end;

function RebuildResponse(aInfo: IInterface; aText: string): Boolean;
var
  sourceResponses, targetResponses, response: IInterface;
begin
  Result := False;
  sourceResponses := ElementByPath(SourceInfo, 'Responses');
  if not Assigned(sourceResponses) or (ElementCount(sourceResponses) <> 1) then begin
    AddMessage('ERROR: Source INFO must have exactly one response row.');
    Exit;
  end;
  targetResponses := ElementByPath(aInfo, 'Responses');
  if Assigned(targetResponses) then
    Remove(targetResponses);
  Add(aInfo, 'Responses', True);
  targetResponses := ElementByPath(aInfo, 'Responses');
  response := ElementAssign(targetResponses, HighInteger,
    ElementByIndex(sourceResponses, 0), False);
  if not Assigned(response) then
    Exit;
  SetElementEditValues(response, 'NAM1', aText);
  Result := SameText(GetElementEditValues(response, 'NAM1'), aText);
end;

function AppendCondition(aConditions, aTemplate: IInterface): Boolean;
begin
  Result := Assigned(ElementAssign(aConditions, HighInteger,
    aTemplate, False));
end;

function RebuildConditions(aInfo: IInterface; aState: Double): Boolean;
var
  conditions, stateCondition, parameter: IInterface;
begin
  Result := False;
  conditions := ElementByPath(aInfo, 'Conditions');
  if Assigned(conditions) then
    Remove(conditions);
  Add(aInfo, 'Conditions', True);
  conditions := ElementByPath(aInfo, 'Conditions');
  if not Assigned(conditions) then
    Exit;
  if not AppendCondition(conditions, CourtWizardCondition) or
     not AppendCondition(conditions, MerchantCondition) then
    Exit;
  stateCondition := ElementAssign(conditions, HighInteger,
    GlobalCondition, False);
  if not Assigned(stateCondition) then
    Exit;
  parameter := ElementByPath(stateCondition, 'CTDA\Parameter #1');
  SetEditValue(parameter, Name(StateGlobal));
  SetElementNativeValues(stateCondition,
    'CTDA\Comparison Value - Float', aState);
  Result := Assigned(LinksTo(parameter)) and
    Equals(MasterOrSelf(LinksTo(parameter)), MasterOrSelf(StateGlobal)) and
    (ElementCount(conditions) = 3);
end;

function InstallActionVmad(aInfo: IInterface; aFragment: string): Boolean;
var
  sourceVmad, targetVmad: IInterface;
begin
  Result := False;
  sourceVmad := ElementBySignature(OpeningInfo, 'VMAD');
  if not Assigned(sourceVmad) then
    Exit;
  targetVmad := ElementBySignature(aInfo, 'VMAD');
  if Assigned(targetVmad) then
    Remove(targetVmad);
  Add(aInfo, 'VMAD', True);
  targetVmad := ElementBySignature(aInfo, 'VMAD');
  if not Assigned(targetVmad) then
    Exit;
  ElementAssign(targetVmad, LowInteger, sourceVmad, False);
  ReplaceTreeValue(targetVmad, RefreshFragmentName, aFragment);
  Result := TreeHasExactValue(targetVmad, HandlerScriptName) and
    TreeHasExactValue(targetVmad, aFragment) and
    TreeHasExactValue(targetVmad, StatePropertyName);
end;

function RebuildInfo(aTopic: IInterface; aEditorID, aPrompt,
  aResponse, aFragment: string; aState: Double): Boolean;
var
  count: Integer;
  info, topicField, previousField, links: IInterface;
begin
  Result := False;
  count := CountRecordsByEditorID(GroupBySignature(TargetFile, 'DIAL'),
    'INFO', aEditorID);
  if count > 1 then begin
    AddMessage('ERROR: Duplicate INFO EditorID ' + aEditorID + '.');
    Exit;
  end;
  if count = 1 then begin
    info := FindRecordByEditorIDRecursive(GroupBySignature(TargetFile,
      'DIAL'), 'INFO', aEditorID);
    Remove(info);
  end;
  info := wbCopyElementToFile(SourceInfo, TargetFile, True, True);
  if not Assigned(info) then
    Exit;
  topicField := ElementByName(info, 'Topic');
  SetEditValue(topicField, Name(aTopic));
  if not Assigned(LinksTo(topicField)) or
     not Equals(MasterOrSelf(LinksTo(topicField)), MasterOrSelf(aTopic)) then
    Exit;
  SetEditorID(info, aEditorID);
  SetElementEditValues(info, 'RNAM', aPrompt);
  previousField := ElementBySignature(info, 'PNAM');
  if Assigned(previousField) then
    Remove(previousField);
  links := ElementByName(info, 'Link To');
  if Assigned(links) then
    Remove(links);
  if not RebuildResponse(info, aResponse) or
     not RebuildConditions(info, aState) or
     not InstallActionVmad(info, aFragment) then
    Exit;
  AddMessage('Configured ' + aEditorID + ': ' + aPrompt);
  Result := True;
end;

function EnsureChoiceLink(aTopic: IInterface): Boolean;
var
  links, template, newLink: IInterface;
begin
  Result := False;
  links := ElementByName(OpeningInfo, 'Link To');
  if not Assigned(links) or (ElementCount(links) = 0) then begin
    AddMessage('ERROR: Opening INFO exposes no Link To template.');
    Exit;
  end;
  if CollectionContainsLink(links, aTopic) then begin
    Result := True;
    Exit;
  end;
  template := ElementByIndex(links, ElementCount(links) - 1);
  newLink := ElementAssign(links, HighInteger, template, False);
  if not Assigned(newLink) then
    Exit;
  SetEditValue(newLink, Name(aTopic));
  Result := Assigned(LinksTo(newLink)) and
    Equals(MasterOrSelf(LinksTo(newLink)), MasterOrSelf(aTopic));
end;

function Initialize: Integer;
var
  addTopic, removeTopic: IInterface;
  openingLinks, vmad, mmeTradeInnTopic: IInterface;
  linksBefore, linksExpected: Integer;
begin
  Result := 1;
  AddMessage('MME Extensions Mage installer revision 6 (OG MME service conditions).');
  TargetFile := FindFileByName(TargetPluginName);
  MMEFile := FindFileByName(MMEPluginName);
  SkyrimFile := FindFileByName(SkyrimPluginName);
  if not Assigned(TargetFile) or not Assigned(MMEFile) or
     not Assigned(SkyrimFile) then begin
    AddMessage('ERROR: Load Skyrim.esm, MilkModNEW.esp, and MMEAlert.esp.');
    Exit;
  end;
  if (GetLoadOrder(SkyrimFile) > GetLoadOrder(TargetFile)) or
     (GetLoadOrder(MMEFile) > GetLoadOrder(TargetFile)) then begin
    AddMessage('ERROR: MMEAlert.esp must load after Skyrim.esm and MilkModNEW.esp.');
    Exit;
  end;

  { Resolve by the actual record identities rather than feeding a file-local
    FormID directly to RecordByFormID. The latter expects a load-order FormID
    and only works accidentally for a plugin at load index 00. }
  OpeningTopicMaster := FindRecordByEditorIDRecursive(
    GroupBySignature(MMEFile, 'DIAL'), 'DIAL', OpeningTopicEditorID);
  OpeningInfoCandidate := nil;
  OpeningInfoCandidateCount := 0;
  FindOpeningInfo(OpeningTopicMaster);
  if OpeningInfoCandidateCount = 1 then
    OpeningInfoMaster := OpeningInfoCandidate
  else
    OpeningInfoMaster := nil;
  if not Assigned(OpeningTopicMaster) or
     not Assigned(OpeningInfoMaster) then begin
    AddMessage('ERROR: Verified MME Hey there records were not found by EditorID/VMAD.');
    if Assigned(OpeningTopicMaster) then
      AddMessage('opening topic found: ' + Name(OpeningTopicMaster))
    else
      AddMessage('opening topic missing: ' + OpeningTopicEditorID);
    AddMessage('Fragment_00 INFO matches=' +
      IntToStr(OpeningInfoCandidateCount));
    Exit;
  end;
  AddMessage('Resolved MME opening topic: ' + Name(OpeningTopicMaster));
  AddMessage('Resolved MME opening INFO: ' + Name(OpeningInfoMaster));
  OpeningTopic := WinningOverride(OpeningTopicMaster);
  OpeningInfo := WinningOverride(OpeningInfoMaster);
  if not Equals(GetFile(OpeningTopic), TargetFile) or
     not Equals(GetFile(OpeningInfo), TargetFile) then begin
    AddMessage('ERROR: MMEAlert.esp is not the winning override for both MME Hey there records.');
    AddMessage('Load every dialogue conflict, resolve it, and place MMEAlert.esp after the chosen winner.');
    Exit;
  end;
  if not AuditTopicOverrides(OpeningTopicMaster, OpeningTopic) or
     not AuditOverrides(OpeningInfoMaster, OpeningInfo,
      'Link To', 'opening INFO choice') then
    Exit;

  SourceTopic := FindRecordByEditorIDRecursive(
    GroupBySignature(TargetFile, 'DIAL'), 'DIAL', SourceTopicEditorID);
  SourceInfo := FindRecordByEditorIDRecursive(
    GroupBySignature(TargetFile, 'DIAL'), 'INFO', SourceInfoEditorID);
  SourceGlobal := FindRecordByEditorIDRecursive(
    GroupBySignature(TargetFile, 'GLOB'), 'GLOB', SourceGlobalEditorID);
  if not Assigned(SourceTopic) or not Assigned(SourceInfo) or
     not Assigned(SourceGlobal) then begin
    AddMessage('ERROR: Current MME Extensions dialogue templates are missing.');
    Exit;
  end;
  JobCourtWizardFaction := FindRecordByEditorIDRecursive(
    GroupBySignature(SkyrimFile, 'FACT'), 'FACT',
    JobCourtWizardFactionEditorID);
  JobMerchantFaction := FindRecordByEditorIDRecursive(
    GroupBySignature(SkyrimFile, 'FACT'), 'FACT',
    JobMerchantFactionEditorID);
  if not Assigned(JobCourtWizardFaction) or
     not Assigned(JobMerchantFaction) then begin
    AddMessage('ERROR: Skyrim job factions were not found.');
    Exit;
  end;

  { Follow the proven vendor-service convention. OG MME supplies the merchant
    row; Skyrim's dialogue supplies the JobCourtWizardFaction row. The service
    does not use GetOffersServicesNow. SourceInfo supplies GetGlobalValue. }
  mmeTradeInnTopic := FindRecordByEditorIDRecursive(
    GroupBySignature(MMEFile, 'DIAL'), 'DIAL', MMETradeInnTopicEditorID);
  if not Assigned(mmeTradeInnTopic) then begin
    AddMessage('ERROR: Verified MME service-condition templates were not found.');
    Exit;
  end;
  FindConditionTemplates(SourceInfo);
  FindConditionTemplates(mmeTradeInnTopic);
  FindConditionTemplates(GroupBySignature(SkyrimFile, 'DIAL'));
  if not Assigned(CourtWizardCondition) or
     not Assigned(MerchantCondition) or
     not Assigned(GlobalCondition) then begin
    AddMessage('ERROR: One or more verified CTDA templates were not found.');
    AddMessage('Inspect OG MME GetInFaction and extension GetGlobalValue templates in the loaded records.');
    Exit;
  end;
  ObjectPropertyTemplate := FindObjectPropTemplate(TargetFile);
  if not Assigned(ObjectPropertyTemplate) then
    ObjectPropertyTemplate := FindObjectPropTemplate(MMEFile);
  if not Assigned(ObjectPropertyTemplate) then begin
    AddMessage('ERROR: No existing VMAD object-property template was found in MMEAlert.esp or MilkModNEW.esp.');
    Exit;
  end;
  if not EnsureStateGlobal then
    Exit;

  vmad := ElementBySignature(OpeningInfo, 'VMAD');
  if not Assigned(vmad) then begin
    AddMessage('ERROR: Opening VMAD vanished before wrapper installation.');
    Exit;
  end;
  if not InstallOpeningWrapper then begin
    AddMessage('ERROR: Opening wrapper installation failed.');
    Exit;
  end;

  addTopic := EnsureTopic(AddTopicEditorID, AddPrompt);
  removeTopic := EnsureTopic(RemoveTopicEditorID, RemovePrompt);
  if not Assigned(addTopic) or not Assigned(removeTopic) then
    Exit;
  if not ValidateTopicWiring(addTopic) or
     not ValidateTopicWiring(removeTopic) then begin
    AddMessage('ERROR: New topics did not preserve the proven quest/branch wiring.');
    Exit;
  end;
  RemoveUnexpectedInfos(addTopic, AddInfoEditorID);
  RemoveUnexpectedInfos(removeTopic, RemoveInfoEditorID);
  if not RebuildInfo(addTopic, AddInfoEditorID, AddPrompt, AddResponse,
      AddFragmentName, 1.0) or
     not RebuildInfo(removeTopic, RemoveInfoEditorID, RemovePrompt,
      RemoveResponse, RemoveFragmentName, 2.0) then begin
    AddMessage('ERROR: Action dialogue construction failed.');
    Exit;
  end;

  openingLinks := ElementByName(OpeningInfo, 'Link To');
  linksBefore := ElementCount(openingLinks);
  linksExpected := linksBefore;
  if not CollectionContainsLink(openingLinks, addTopic) then
    Inc(linksExpected);
  if not CollectionContainsLink(openingLinks, removeTopic) then
    Inc(linksExpected);
  if not EnsureChoiceLink(addTopic) or not EnsureChoiceLink(removeTopic) then begin
    AddMessage('ERROR: Could not append both opening choices.');
    Exit;
  end;
  if ElementCount(openingLinks) <> linksExpected then begin
    AddMessage('ERROR: Opening Link To count did not verify.');
    Exit;
  end;

  AddMessage('MME Extensions Mage dialogue installed successfully.');
  AddMessage('Opening VMAD preserved and wrapped: ' + HandlerScriptName +
    '.' + RefreshFragmentName);
  AddMessage('Added exactly two state-exclusive choices; no new branch or quest.');
  AddMessage('Save MMEAlert.esp, then run Check for Errors before closing SSEEdit.');
  Result := 0;
end;

end.
