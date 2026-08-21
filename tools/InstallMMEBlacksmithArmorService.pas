unit UserScript;

{
  Installs the MME Extensions Blacksmith Armor Service dialogue tree.

  Architecture:
    MMEAlertDebugQuest (existing start-game-enabled quest)
      -> MMEExt_BlacksmithArmorServiceBranch (new top-level branch)
      -> root offer DIAL/INFO
      -> state-conditioned modification, removal, native, or unavailable DIALs
      -> confirmation DIALs call MMEVendorServices fragments

  The script copies Skyrim's top-level ServicesBranch/OfferServicesTopic shape,
  then retargets the copied branch and topics to MMEAlertDebugQuest. This avoids
  relying on QNAM/BNAM alone: the new DLBR explicitly names the new root DIAL as
  its starting topic. All generated records use stable EditorIDs and are updated
  in place on rerun. Duplicate EditorIDs abort before that record is changed.

  Required loaded files:
    Skyrim.esm
    MilkModNEW.esp
    MMEAlert.esp
}

const
  TargetPluginName = 'MMEAlert.esp';
  MMEPluginName = 'MilkModNEW.esp';
  SkyrimPluginName = 'Skyrim.esm';
  TargetQuestEditorID = 'MMEAlertDebugQuest';
  SourceBranchEditorID = 'ServicesBranch';
  SourceTopicEditorID = 'OfferServicesTopic';
  JobBlacksmithFactionEditorID = 'JobBlacksmithFaction';
  MilkMaidFactionEditorID = 'MME_MilkMaidFaction';
  ArmorCuirassKeywordEditorID = 'ArmorCuirass';
  ClothingBodyKeywordEditorID = 'ClothingBody';
  HandlerScriptName = 'MMEVendorServices';

  SourceBranchLocalFormID = $0007F6BD;
  SourceTopicLocalFormID = $0007F6BB;
  JobBlacksmithFactionLocalFormID = $0005091D;
  MilkMaidFactionLocalFormID = $0004D53B;
  ArmorCuirassKeywordLocalFormID = $0006C0EC;
  ClothingBodyKeywordLocalFormID = $000A8657;
  OpeningInfoLocalFormID = $0006544B;

  ServiceAvailableGlobalID = 'MMEExt_BlacksmithServiceAvailable';
  ServiceStateGlobalID = 'MMEExt_BlacksmithServiceState';
  HasMilkGlobalID = 'MMEExt_BlacksmithHasMilk';
  HasFreeSlotGlobalID = 'MMEExt_BlacksmithHasFreeSlot';

  BranchEditorID = 'MMEExt_BlacksmithArmorServiceBranch';
  RootTopicID = 'MMEExt_BlacksmithArmorServiceTopic';
  ModifyTopicID = 'MMEExt_BlacksmithModifyTopic';
  RemoveTopicID = 'MMEExt_BlacksmithRemoveTopic';
  NativeTopicID = 'MMEExt_BlacksmithNativeTopic';
  UnavailableTopicID = 'MMEExt_BlacksmithUnavailableTopic';
  ConfirmModifyTopicID = 'MMEExt_BlacksmithConfirmModifyTopic';
  ConfirmRemoveTopicID = 'MMEExt_BlacksmithConfirmRemoveTopic';
  NoMilkTopicID = 'MMEExt_BlacksmithNoMilkTopic';
  FullTopicID = 'MMEExt_BlacksmithFullTopic';
  CancelTopicID = 'MMEExt_BlacksmithCancelTopic';

  RootInfoID = 'MMEExt_BlacksmithArmorService';
  ModifyInfoID = 'MMEExt_BlacksmithModify';
  RemoveInfoID = 'MMEExt_BlacksmithRemove';
  NativeInfoID = 'MMEExt_BlacksmithNative';
  UnavailableInfoID = 'MMEExt_BlacksmithUnavailable';
  ConfirmModifyInfoID = 'MMEExt_BlacksmithConfirmModify';
  ConfirmRemoveInfoID = 'MMEExt_BlacksmithConfirmRemove';
  NoMilkInfoID = 'MMEExt_BlacksmithNoMilk';
  FullInfoID = 'MMEExt_BlacksmithFull';
  CancelInfoID = 'MMEExt_BlacksmithCancel';

var
  TargetFile, MMEFile, SkyrimFile: IInterface;
  TargetQuest, SourceBranch, SourceTopic, OpeningInfo: IInterface;
  JobBlacksmithFaction, MilkMaidFaction: IInterface;
  ArmorCuirassKeyword, ClothingBodyKeyword: IInterface;
  ServiceAvailableGlobal, ServiceStateGlobal: IInterface;
  HasMilkGlobal, HasFreeSlotGlobal: IInterface;
  TargetBranch: IInterface;
  RootTopic, ModifyTopic, RemoveTopic, NativeTopic: IInterface;
  UnavailableTopic, ConfirmModifyTopic, ConfirmRemoveTopic: IInterface;
  NoMilkTopic, FullTopic, CancelTopic: IInterface;
  OpeningMatches: Integer;

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

function ResolveRecord(aFile: IInterface; aSignature,
  aEditorID: string): IInterface;
begin
  Result := FindRecordByEditorIDRecursive(GroupBySignature(aFile, aSignature),
    aSignature, aEditorID);
  if Assigned(Result) then
    AddMessage('Resolved ' + aEditorID + ': ' + Name(Result))
  else
    AddMessage('ERROR: Could not resolve ' + aEditorID + ' [' +
      aSignature + '] from ' + GetFileName(aFile) + '.');
end;

function ResolveKnownRecord(aFile: IInterface; aSignature,
  aEditorID: string; aLocalFormID: Cardinal): IInterface;
begin
  { Resolve verified local IDs first. Recursively walking Skyrim's entire DIAL
    tree is correct but extremely slow because it also traverses every INFO
    child. EditorID/signature validation keeps the fast path fail-closed. }
  Result := RecordByFormID(aFile, aLocalFormID, True);
  if Assigned(Result) and
     ((Signature(Result) <> aSignature) or
      not SameText(EditorID(Result), aEditorID)) then
    Result := nil;
  if not Assigned(Result) then
    Result := ResolveRecord(aFile, aSignature, aEditorID)
  else
    AddMessage('Resolved ' + aEditorID + ': ' + Name(Result));
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

procedure FindOpeningInfoRecursive(aElement: IInterface);
var
  i: Integer;
  vmad: IInterface;
begin
  if not Assigned(aElement) then
    Exit;
  if Signature(aElement) = 'INFO' then begin
    vmad := ElementBySignature(aElement, 'VMAD');
    if Assigned(vmad) and TreeHasExactValue(vmad, 'MME_Dialogues') and
       TreeHasExactValue(vmad, 'Fragment_00') then begin
      Inc(OpeningMatches);
      OpeningInfo := aElement;
    end;
  end;
  for i := 0 to ElementCount(aElement) - 1 do
    FindOpeningInfoRecursive(ElementByIndex(aElement, i));
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

function EnsureGlobal(aEditorID: string; aInitialValue: Double): IInterface;
var
  template: IInterface;
  count: Integer;
begin
  Result := nil;
  count := CountRecordsByEditorID(GroupBySignature(TargetFile, 'GLOB'),
    'GLOB', aEditorID);
  if count > 1 then begin
    AddMessage('ERROR: Duplicate GLOB EditorID ' + aEditorID + '.');
    Exit;
  end;
  if count = 1 then begin
    Result := FindRecordByEditorIDRecursive(GroupBySignature(TargetFile,
      'GLOB'), 'GLOB', aEditorID);
    AddMessage('Updating global: ' + Name(Result));
  end else begin
    template := RecordByFormID(SkyrimFile, $00000038, True);
    if not Assigned(template) or (Signature(template) <> 'GLOB') then begin
      AddMessage('ERROR: Skyrim GameHour global template is unavailable.');
      Exit;
    end;
    Result := wbCopyElementToFile(template, TargetFile, True, True);
    if not Assigned(Result) then begin
      AddMessage('ERROR: Could not create global ' + aEditorID + '.');
      Exit;
    end;
    AddMessage('Created global: ' + aEditorID);
  end;
  SetEditorID(Result, aEditorID);
  SetElementNativeValues(Result, 'FLTV', aInitialValue);
end;

function EnsureBranch: IInterface;
var
  count: Integer;
begin
  Result := nil;
  count := CountRecordsByEditorID(GroupBySignature(TargetFile, 'DLBR'),
    'DLBR', BranchEditorID);
  if count > 1 then begin
    AddMessage('ERROR: Duplicate DLBR EditorID ' + BranchEditorID + '.');
    Exit;
  end;
  if count = 1 then begin
    Result := FindRecordByEditorIDRecursive(GroupBySignature(TargetFile,
      'DLBR'), 'DLBR', BranchEditorID);
    AddMessage('Reusing branch: ' + Name(Result));
  end else begin
    AddRequiredElementMasters(SourceBranch, TargetFile, False);
    Result := wbCopyElementToFile(SourceBranch, TargetFile, True, True);
    if not Assigned(Result) then begin
      AddMessage('ERROR: Could not copy Skyrim ServicesBranch.');
      Exit;
    end;
    AddMessage('Created top-level service branch.');
  end;
  SetEditorID(Result, BranchEditorID);
  SetEditValue(ElementBySignature(Result, 'QNAM'), Name(TargetQuest));
  if not Assigned(LinksTo(ElementBySignature(Result, 'QNAM'))) or
     not Equals(MasterOrSelf(LinksTo(ElementBySignature(Result, 'QNAM'))),
       MasterOrSelf(TargetQuest)) then begin
    AddMessage('ERROR: Branch QNAM did not resolve to ' +
      TargetQuestEditorID + '.');
    Result := nil;
  end;
end;

function EnsureTopic(aEditorID, aFullName: string): IInterface;
var
  count: Integer;
  sourceElement, targetElement: IInterface;
begin
  Result := nil;
  count := CountRecordsByEditorID(GroupBySignature(TargetFile, 'DIAL'),
    'DIAL', aEditorID);
  if count > 1 then begin
    AddMessage('ERROR: Duplicate DIAL EditorID ' + aEditorID + '.');
    Exit;
  end;
  if count = 1 then begin
    Result := FindRecordByEditorIDRecursive(GroupBySignature(TargetFile,
      'DIAL'), 'DIAL', aEditorID);
    AddMessage('Reusing topic: ' + Name(Result));
  end else begin
    AddRequiredElementMasters(SourceTopic, TargetFile, False);
    { Copy only the DIAL record. A deep copy also clones every vanilla service
      INFO child, makes each generated topic unnecessarily large, and is the
      main reason an initial installation can take more than a minute. }
    Result := wbCopyElementToFile(SourceTopic, TargetFile, True, False);
    if not Assigned(Result) then begin
      AddMessage('ERROR: Could not copy OfferServicesTopic for ' + aEditorID + '.');
      Exit;
    end;
    AddMessage('Created topic: ' + aEditorID);
  end;

  { A shallow xEdit copy intentionally creates only the DIAL record shell.
    Restore the non-child fields that define a Custom dialogue topic, then
    retarget its quest and branch below. TIFC is omitted because xEdit owns the
    live child-INFO count. }
  sourceElement := ElementBySignature(SourceTopic, 'FULL');
  targetElement := ElementBySignature(Result, 'FULL');
  if not Assigned(targetElement) then
    targetElement := Add(Result, 'FULL', True);
  if Assigned(sourceElement) and Assigned(targetElement) then
    SetEditValue(targetElement, GetEditValue(sourceElement));

  sourceElement := ElementBySignature(SourceTopic, 'PNAM');
  targetElement := ElementBySignature(Result, 'PNAM');
  if not Assigned(targetElement) then
    targetElement := Add(Result, 'PNAM', True);
  if Assigned(sourceElement) and Assigned(targetElement) then
    SetEditValue(targetElement, GetEditValue(sourceElement));

  sourceElement := ElementBySignature(SourceTopic, 'BNAM');
  targetElement := ElementBySignature(Result, 'BNAM');
  if not Assigned(targetElement) then
    targetElement := Add(Result, 'BNAM', True);
  if Assigned(sourceElement) and Assigned(targetElement) then
    SetEditValue(targetElement, GetEditValue(sourceElement));

  sourceElement := ElementBySignature(SourceTopic, 'QNAM');
  targetElement := ElementBySignature(Result, 'QNAM');
  if not Assigned(targetElement) then
    targetElement := Add(Result, 'QNAM', True);
  if Assigned(sourceElement) and Assigned(targetElement) then
    SetEditValue(targetElement, GetEditValue(sourceElement));

  sourceElement := ElementBySignature(SourceTopic, 'DATA');
  targetElement := ElementBySignature(Result, 'DATA');
  if not Assigned(targetElement) then
    targetElement := Add(Result, 'DATA', True);
  if Assigned(sourceElement) and Assigned(targetElement) then
    SetEditValue(targetElement, GetEditValue(sourceElement));

  sourceElement := ElementBySignature(SourceTopic, 'SNAM');
  targetElement := ElementBySignature(Result, 'SNAM');
  if not Assigned(targetElement) then
    targetElement := Add(Result, 'SNAM', True);
  if Assigned(sourceElement) and Assigned(targetElement) then
    SetEditValue(targetElement, GetEditValue(sourceElement));

  SetEditorID(Result, aEditorID);
  SetElementEditValues(Result, 'FULL', aFullName);
  SetEditValue(ElementBySignature(Result, 'QNAM'), Name(TargetQuest));
  SetEditValue(ElementBySignature(Result, 'BNAM'), Name(TargetBranch));
  if not Assigned(LinksTo(ElementBySignature(Result, 'QNAM'))) or
     not Assigned(LinksTo(ElementBySignature(Result, 'BNAM'))) or
     not Equals(MasterOrSelf(LinksTo(ElementBySignature(Result, 'QNAM'))),
       MasterOrSelf(TargetQuest)) or
     not Equals(MasterOrSelf(LinksTo(ElementBySignature(Result, 'BNAM'))),
       MasterOrSelf(TargetBranch)) then begin
    AddMessage('ERROR: Topic quest/branch links failed for ' + aEditorID + '.');
    Result := nil;
  end;
end;

function SetBranchStartingTopic(aTopic: IInterface): Boolean;
var
  startElement, linkedTopic: IInterface;
begin
  Result := False;
  startElement := ElementBySignature(TargetBranch, 'SNAM');
  if not Assigned(startElement) then begin
    AddMessage('ERROR: Copied ServicesBranch exposes no SNAM starting topic.');
    Exit;
  end;
  SetEditValue(startElement, Name(aTopic));
  linkedTopic := LinksTo(startElement);
  Result := Assigned(linkedTopic) and
    Equals(MasterOrSelf(linkedTopic), MasterOrSelf(aTopic));
  if Result then
    AddMessage('Branch starting topic: ' + Name(linkedTopic))
  else
    AddMessage('ERROR: Branch SNAM did not resolve to the new root topic.');
end;

function AddRecordCondition(aConditions, aTemplate: IInterface;
  aFunctionName: string; aRecord: IInterface; aRunOn: string;
  aComparison: Double; aUseOr: Boolean): Boolean;
var
  condition, cis: IInterface;
  conditionType: Integer;
begin
  Result := False;
  if not Assigned(aConditions) or not Assigned(aTemplate) or
     not Assigned(aRecord) then
    Exit;
  AddRequiredElementMasters(aRecord, TargetFile, False);
  condition := ElementAssign(aConditions, HighInteger, aTemplate, False);
  if not Assigned(condition) then
    Exit;
  SetElementEditValues(condition, 'CTDA\Function', aFunctionName);
  SetElementEditValues(condition, 'CTDA\Run On', aRunOn);
  SetElementNativeValues(condition, 'CTDA\Comparison Value - Float',
    aComparison);
  SetEditValue(ElementByPath(condition, 'CTDA\Parameter #1'), Name(aRecord));
  { Parameter #2 is unused by every function installed here. Do not write a
    native integer into this variant field: xEdit 4.1.5f raises a runtime type
    mismatch even though the field appears writable in the record view. }
  cis := ElementBySignature(condition, 'CIS1');
  if Assigned(cis) then
    Remove(cis);
  cis := ElementBySignature(condition, 'CIS2');
  if Assigned(cis) then
    Remove(cis);
  conditionType := GetElementNativeValues(condition, 'CTDA\Type');
  if aUseOr then
    conditionType := conditionType or 1
  else
    conditionType := conditionType and $FE;
  SetElementNativeValues(condition, 'CTDA\Type', conditionType);
  Result := SameText(GetElementEditValues(condition, 'CTDA\Function'),
      aFunctionName) and
    Assigned(LinksTo(ElementByPath(condition, 'CTDA\Parameter #1'))) and
    Equals(MasterOrSelf(LinksTo(ElementByPath(condition,
      'CTDA\Parameter #1'))), MasterOrSelf(aRecord));
end;

procedure PruneUnexpectedTopicInfos(aTopic: IInterface;
  aExpectedEditorID: string);
var
  children, candidate: IInterface;
  i: Integer;
begin
  { Early versions deep-copied OfferServicesTopic and could leave vanilla
    service INFO children inside one of our generated DIALs after an aborted
    run. Remove only those foreign children; preserve our stable INFO on rerun. }
  children := ChildGroup(aTopic);
  if not Assigned(children) then
    Exit;
  for i := ElementCount(children) - 1 downto 0 do begin
    candidate := ElementByIndex(children, i);
    if (Signature(candidate) = 'INFO') and
       not SameText(EditorID(candidate), aExpectedEditorID) then begin
      AddMessage('Removing unexpected copied INFO from ' + EditorID(aTopic) +
        ': ' + Name(candidate));
      Remove(candidate);
    end;
  end;
end;

function RebuildConditions(aInfo: IInterface; aMode: Integer): Boolean;
var
  sourceConditions, template, targetConditions: IInterface;
begin
  Result := False;
  sourceConditions := ElementByPath(OpeningInfo, 'Conditions');
  if not Assigned(sourceConditions) or (ElementCount(sourceConditions) = 0) then begin
    AddMessage('ERROR: Fragment_00 INFO provides no CTDA template.');
    Exit;
  end;
  template := ElementByIndex(sourceConditions, 0);
  targetConditions := ElementByPath(aInfo, 'Conditions');
  if Assigned(targetConditions) then
    Remove(targetConditions);
  Add(aInfo, 'Conditions', True);
  targetConditions := ElementByPath(aInfo, 'Conditions');
  if not Assigned(targetConditions) then
    Exit;

  if not AddRecordCondition(targetConditions, template, 'GetGlobalValue',
      ServiceAvailableGlobal, 'Subject', 1.0, False) then
    Exit;

  if aMode = 0 then begin
    if not AddRecordCondition(targetConditions, template, 'GetInFaction',
        JobBlacksmithFaction, 'Subject', 1.0, False) or
       not AddRecordCondition(targetConditions, template, 'GetInFaction',
        MilkMaidFaction, 'Target', 1.0, False) or
       not AddRecordCondition(targetConditions, template, 'WornHasKeyword',
        ArmorCuirassKeyword, 'Target', 1.0, True) or
       not AddRecordCondition(targetConditions, template, 'WornHasKeyword',
        ClothingBodyKeyword, 'Target', 1.0, False) then
      Exit;
  end else if aMode = 1 then begin
    if not AddRecordCondition(targetConditions, template, 'GetGlobalValue',
        ServiceStateGlobal, 'Subject', 1.0, False) then Exit;
  end else if aMode = 2 then begin
    if not AddRecordCondition(targetConditions, template, 'GetGlobalValue',
        ServiceStateGlobal, 'Subject', 2.0, False) then Exit;
  end else if aMode = 3 then begin
    if not AddRecordCondition(targetConditions, template, 'GetGlobalValue',
        ServiceStateGlobal, 'Subject', 3.0, False) then Exit;
  end else if aMode = 4 then begin
    if not AddRecordCondition(targetConditions, template, 'GetGlobalValue',
        ServiceStateGlobal, 'Subject', 0.0, False) then Exit;
  end else if aMode = 5 then begin
    if not AddRecordCondition(targetConditions, template, 'GetGlobalValue',
        ServiceStateGlobal, 'Subject', 1.0, False) or
       not AddRecordCondition(targetConditions, template, 'GetGlobalValue',
        HasMilkGlobal, 'Subject', 1.0, False) or
       not AddRecordCondition(targetConditions, template, 'GetGlobalValue',
        HasFreeSlotGlobal, 'Subject', 1.0, False) then Exit;
  end else if aMode = 6 then begin
    if not AddRecordCondition(targetConditions, template, 'GetGlobalValue',
        ServiceStateGlobal, 'Subject', 1.0, False) or
       not AddRecordCondition(targetConditions, template, 'GetGlobalValue',
        HasFreeSlotGlobal, 'Subject', 1.0, False) or
       not AddRecordCondition(targetConditions, template, 'GetGlobalValue',
        HasMilkGlobal, 'Subject', 0.0, False) then Exit;
  end else if aMode = 7 then begin
    if not AddRecordCondition(targetConditions, template, 'GetGlobalValue',
        ServiceStateGlobal, 'Subject', 1.0, False) or
       not AddRecordCondition(targetConditions, template, 'GetGlobalValue',
        HasFreeSlotGlobal, 'Subject', 0.0, False) then Exit;
  end else if aMode = 8 then begin
    if not AddRecordCondition(targetConditions, template, 'GetGlobalValue',
        ServiceStateGlobal, 'Subject', 2.0, False) then Exit;
  end;
  Result := True;
end;

function ConfigureResponse(aInfo: IInterface; aResponseText: string): Boolean;
var
  responses, response: IInterface;
begin
  Result := False;
  responses := ElementByPath(aInfo, 'Responses');
  if not Assigned(responses) or (ElementCount(responses) = 0) then begin
    AddMessage('ERROR: Copied INFO has no response template.');
    Exit;
  end;
  while ElementCount(responses) > 1 do
    Remove(ElementByIndex(responses, ElementCount(responses) - 1));
  response := ElementByIndex(responses, 0);
  SetElementEditValues(response, 'NAM1', aResponseText);
  Result := SameText(GetElementEditValues(response, 'NAM1'), aResponseText);
end;

function InstallFragment(aInfo: IInterface; aFragmentName: string): Boolean;
var
  sourceVmad, targetVmad: IInterface;
begin
  Result := False;
  targetVmad := ElementBySignature(aInfo, 'VMAD');
  if Assigned(targetVmad) then
    Remove(targetVmad);
  if aFragmentName = '' then begin
    Result := True;
    Exit;
  end;
  sourceVmad := ElementBySignature(OpeningInfo, 'VMAD');
  if not Assigned(sourceVmad) then begin
    AddMessage('ERROR: Fragment_00 VMAD template is unavailable.');
    Exit;
  end;
  Add(aInfo, 'VMAD', True);
  targetVmad := ElementBySignature(aInfo, 'VMAD');
  if not Assigned(targetVmad) then
    Exit;
  ElementAssign(targetVmad, LowInteger, sourceVmad, False);
  ReplaceTreeValue(targetVmad, 'MME_Dialogues', HandlerScriptName);
  ReplaceTreeValue(targetVmad, 'Fragment_00', aFragmentName);
  Result := TreeHasExactValue(targetVmad, HandlerScriptName) and
    TreeHasExactValue(targetVmad, aFragmentName) and
    not TreeHasExactValue(targetVmad, 'MME_Dialogues');
end;

function RebuildLinks(aInfo: IInterface; aLinkCount: Integer;
  aLink1, aLink2, aLink3, aLink4: IInterface): Boolean;
var
  targetLinks, sourceLinks, sourceTemplate, linkElement, linkedTopic: IInterface;
  i: Integer;
begin
  Result := False;
  targetLinks := ElementByName(aInfo, 'Link To');
  if Assigned(targetLinks) then
    Remove(targetLinks);
  if aLinkCount = 0 then begin
    Result := True;
    Exit;
  end;
  sourceLinks := ElementByName(OpeningInfo, 'Link To');
  if not Assigned(sourceLinks) or (ElementCount(sourceLinks) = 0) then begin
    AddMessage('ERROR: Fragment_00 INFO provides no TCLT template.');
    Exit;
  end;

  { Create the grouped Link To array before adding individual TCLT entries.
    Appending a TCLT directly to the INFO root can look valid in the tree while
    failing to join xEdit's array container on some record definitions. }
  Add(aInfo, 'Link To', True);
  targetLinks := ElementByName(aInfo, 'Link To');
  if not Assigned(targetLinks) then begin
    AddMessage('ERROR: Could not create the INFO Link To array.');
    Exit;
  end;
  sourceTemplate := ElementByIndex(sourceLinks, 0);
  for i := 1 to aLinkCount do begin
    linkElement := ElementAssign(targetLinks, HighInteger, sourceTemplate, False);
    if not Assigned(linkElement) then
      Exit;
    if i = 1 then SetEditValue(linkElement, Name(aLink1));
    if i = 2 then SetEditValue(linkElement, Name(aLink2));
    if i = 3 then SetEditValue(linkElement, Name(aLink3));
    if i = 4 then SetEditValue(linkElement, Name(aLink4));
    linkedTopic := LinksTo(linkElement);
    if not Assigned(linkedTopic) then begin
      AddMessage('ERROR: A rebuilt TCLT link did not resolve.');
      Exit;
    end;
  end;
  Result := Assigned(targetLinks) and
    (ElementCount(targetLinks) = aLinkCount);
end;

function EnsureInfo(aTopic: IInterface; aEditorID, aPrompt,
  aResponse, aFragment: string; aConditionMode, aLinkCount: Integer;
  aLink1, aLink2, aLink3, aLink4: IInterface): Boolean;
var
  count: Integer;
  info, topicElement, previousElement: IInterface;
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
    AddMessage('Updating INFO: ' + Name(info));
  end else begin
    AddRequiredElementMasters(OpeningInfo, TargetFile, False);
    info := wbCopyElementToFile(OpeningInfo, TargetFile, True, True);
    if not Assigned(info) then begin
      AddMessage('ERROR: Could not create INFO ' + aEditorID + '.');
      Exit;
    end;
    AddMessage('Created INFO: ' + aEditorID);
  end;

  topicElement := ElementByName(info, 'Topic');
  if not Assigned(topicElement) then begin
    AddMessage('ERROR: INFO has no xEdit Topic relationship: ' + aEditorID);
    Exit;
  end;
  SetEditValue(topicElement, Name(aTopic));
  if not Assigned(LinksTo(topicElement)) or
     not Equals(MasterOrSelf(LinksTo(topicElement)), MasterOrSelf(aTopic)) then begin
    AddMessage('ERROR: INFO could not be moved to topic: ' + aEditorID);
    Exit;
  end;
  SetEditorID(info, aEditorID);
  SetElementEditValues(info, 'RNAM', aPrompt);
  previousElement := ElementBySignature(info, 'PNAM');
  if Assigned(previousElement) then
    Remove(previousElement);

  if not ConfigureResponse(info, aResponse) or
     not RebuildConditions(info, aConditionMode) or
     not InstallFragment(info, aFragment) or
     not RebuildLinks(info, aLinkCount, aLink1, aLink2, aLink3,
       aLink4) then begin
    AddMessage('ERROR: Configuration failed for INFO ' + aEditorID + '.');
    Exit;
  end;
  AddMessage('  ' + aPrompt + ' -> ' + aResponse);
  if aFragment <> '' then
    AddMessage('  Fragment: ' + HandlerScriptName + '.' + aFragment);
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
  if (GetLoadOrder(SkyrimFile) > GetLoadOrder(TargetFile)) or
     (GetLoadOrder(MMEFile) > GetLoadOrder(TargetFile)) then begin
    AddMessage('ERROR: ' + TargetPluginName +
      ' must load after Skyrim and MME. No records were modified.');
    Exit;
  end;

  TargetQuest := ResolveRecord(TargetFile, 'QUST', TargetQuestEditorID);
  SourceBranch := ResolveKnownRecord(SkyrimFile, 'DLBR',
    SourceBranchEditorID, SourceBranchLocalFormID);
  SourceTopic := ResolveKnownRecord(SkyrimFile, 'DIAL', SourceTopicEditorID,
    SourceTopicLocalFormID);
  JobBlacksmithFaction := ResolveKnownRecord(SkyrimFile, 'FACT',
    JobBlacksmithFactionEditorID, JobBlacksmithFactionLocalFormID);
  MilkMaidFaction := ResolveKnownRecord(MMEFile, 'FACT',
    MilkMaidFactionEditorID, MilkMaidFactionLocalFormID);
  ArmorCuirassKeyword := ResolveKnownRecord(SkyrimFile, 'KYWD',
    ArmorCuirassKeywordEditorID, ArmorCuirassKeywordLocalFormID);
  ClothingBodyKeyword := ResolveKnownRecord(SkyrimFile, 'KYWD',
    ClothingBodyKeywordEditorID, ClothingBodyKeywordLocalFormID);
  if not Assigned(TargetQuest) or not Assigned(SourceBranch) or
     not Assigned(SourceTopic) or not Assigned(JobBlacksmithFaction) or
     not Assigned(MilkMaidFaction) or not Assigned(ArmorCuirassKeyword) or
     not Assigned(ClothingBodyKeyword) then begin
    AddMessage('ERROR: One or more authoritative records are missing.');
    Exit;
  end;

  OpeningInfo := RecordByFormID(MMEFile, OpeningInfoLocalFormID, True);
  if not Assigned(OpeningInfo) or (Signature(OpeningInfo) <> 'INFO') or
     not TreeHasExactValue(ElementBySignature(OpeningInfo, 'VMAD'),
       'MME_Dialogues') or
     not TreeHasExactValue(ElementBySignature(OpeningInfo, 'VMAD'),
       'Fragment_00') then begin
    OpeningInfo := nil;
    OpeningMatches := 0;
    FindOpeningInfoRecursive(GroupBySignature(MMEFile, 'DIAL'));
    if OpeningMatches <> 1 then begin
      AddMessage('ERROR: Expected exactly one MME Fragment_00 INFO, found ' +
        IntToStr(OpeningMatches) + '. No records were modified.');
      Exit;
    end;
  end;
  AddMessage('Validated VMAD/CTDA/TCLT template: ' + Name(OpeningInfo));

  { Fail closed until MMEAlertsController synchronizes the master toggle. }
  ServiceAvailableGlobal := EnsureGlobal(ServiceAvailableGlobalID, 0.0);
  ServiceStateGlobal := EnsureGlobal(ServiceStateGlobalID, 0.0);
  HasMilkGlobal := EnsureGlobal(HasMilkGlobalID, 0.0);
  HasFreeSlotGlobal := EnsureGlobal(HasFreeSlotGlobalID, 0.0);
  if not Assigned(ServiceAvailableGlobal) or
     not Assigned(ServiceStateGlobal) or not Assigned(HasMilkGlobal) or
     not Assigned(HasFreeSlotGlobal) then
    Exit;

  TargetBranch := EnsureBranch;
  if not Assigned(TargetBranch) then
    Exit;
  RootTopic := EnsureTopic(RootTopicID, 'MME Extensions Blacksmith Armor Service');
  ModifyTopic := EnsureTopic(ModifyTopicID, 'MME Extensions Blacksmith Modify');
  RemoveTopic := EnsureTopic(RemoveTopicID, 'MME Extensions Blacksmith Remove');
  NativeTopic := EnsureTopic(NativeTopicID, 'MME Extensions Blacksmith Native Armor');
  UnavailableTopic := EnsureTopic(UnavailableTopicID, 'MME Extensions Blacksmith Unavailable');
  ConfirmModifyTopic := EnsureTopic(ConfirmModifyTopicID, 'MME Extensions Confirm Modification');
  ConfirmRemoveTopic := EnsureTopic(ConfirmRemoveTopicID, 'MME Extensions Confirm Removal');
  NoMilkTopic := EnsureTopic(NoMilkTopicID, 'MME Extensions Blacksmith No Milk');
  FullTopic := EnsureTopic(FullTopicID, 'MME Extensions Blacksmith Full');
  CancelTopic := EnsureTopic(CancelTopicID, 'MME Extensions Blacksmith Cancel');
  if not Assigned(RootTopic) or not Assigned(ModifyTopic) or
     not Assigned(RemoveTopic) or not Assigned(NativeTopic) or
     not Assigned(UnavailableTopic) or not Assigned(ConfirmModifyTopic) or
     not Assigned(ConfirmRemoveTopic) or not Assigned(NoMilkTopic) or
     not Assigned(FullTopic) or not Assigned(CancelTopic) then
    Exit;

  { Repair a saved or still-open partial run from the earlier deep-copy
    implementation before configuring the one owned INFO under each topic. }
  PruneUnexpectedTopicInfos(RootTopic, RootInfoID);
  PruneUnexpectedTopicInfos(ModifyTopic, ModifyInfoID);
  PruneUnexpectedTopicInfos(RemoveTopic, RemoveInfoID);
  PruneUnexpectedTopicInfos(NativeTopic, NativeInfoID);
  PruneUnexpectedTopicInfos(UnavailableTopic, UnavailableInfoID);
  PruneUnexpectedTopicInfos(ConfirmModifyTopic, ConfirmModifyInfoID);
  PruneUnexpectedTopicInfos(ConfirmRemoveTopic, ConfirmRemoveInfoID);
  PruneUnexpectedTopicInfos(NoMilkTopic, NoMilkInfoID);
  PruneUnexpectedTopicInfos(FullTopic, FullInfoID);
  PruneUnexpectedTopicInfos(CancelTopic, CancelInfoID);
  if not SetBranchStartingTopic(RootTopic) then
    Exit;

  if not EnsureInfo(RootTopic, RootInfoID,
      'Could you adjust my armor for milking?',
      'Let''s have a look at what you''re wearing.', 'Fragment_Prepare', 0, 4,
      ModifyTopic, RemoveTopic, NativeTopic, UnavailableTopic) then Exit;
  if not EnsureInfo(ModifyTopic, ModifyInfoID,
      'Could you make this armor work better for a Milkmaid?',
      'You Milkmaids do plenty for this community. A bottle of milk while I work is more than enough.',
      '', 1, 4, ConfirmModifyTopic, NoMilkTopic, FullTopic, CancelTopic) then Exit;
  if not EnsureInfo(RemoveTopic, RemoveInfoID,
      'Could you remove the milking modifications?',
      'I can strip those modifications back out for you. Won''t cost anything.',
      '', 2, 2, ConfirmRemoveTopic, CancelTopic, nil, nil) then Exit;
  if not EnsureInfo(NativeTopic, NativeInfoID,
      'What about this armor?',
      'That armor already has its own milking design. I shouldn''t alter it.',
      '', 3, 0, nil, nil, nil, nil) then Exit;
  if not EnsureInfo(UnavailableTopic, UnavailableInfoID,
      'Is there a problem with my armor?',
      'I can''t safely work on what you''re wearing right now.',
      '', 4, 0, nil, nil, nil, nil) then Exit;
  if not EnsureInfo(ConfirmModifyTopic, ConfirmModifyInfoID,
      'A bottle of milk sounds fair. Go ahead.',
      'All right. Hold still while I open the chest and fit the collection pieces.',
      'Fragment_Modify', 5, 0, nil, nil, nil, nil) then Exit;
  if not EnsureInfo(NoMilkTopic, NoMilkInfoID,
      'I don''t have a bottle of milk with me.',
      'Bring me one bottle of milk and I''ll do the work.',
      '', 6, 0, nil, nil, nil, nil) then Exit;
  if not EnsureInfo(FullTopic, FullInfoID,
      'Can you still modify it?',
      'Your Milking Equipment list is full. Have another modified armor stripped first.',
      '', 7, 0, nil, nil, nil, nil) then Exit;
  if not EnsureInfo(ConfirmRemoveTopic, ConfirmRemoveInfoID,
      'Yes, return it to normal.',
      'All right. I''ll strip the fittings out without harming the armor.',
      'Fragment_Remove', 8, 0, nil, nil, nil, nil) then Exit;
  if not EnsureInfo(CancelTopic, CancelInfoID,
      'Never mind.', 'Suit yourself.', 'Fragment_Cancel', 9, 0,
      nil, nil, nil, nil) then Exit;

  AddMessage('MME Extensions Blacksmith Armor Service installed successfully.');
  AddMessage('Branch: ' + Name(TargetBranch));
  AddMessage('Starting topic: ' + Name(RootTopic));
  AddMessage('Eligibility: JobBlacksmithFaction Subject + MME MilkMaidFaction Target + slot-32 body keywords.');
  AddMessage('Runtime state/commit owner: MMEVendorServices.psc');
  AddMessage('Safe to save ' + TargetPluginName + '. Rerunning updates these stable EditorIDs.');
  Result := 0;
end;

end.
