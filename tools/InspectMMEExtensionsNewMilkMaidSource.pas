unit UserScript;

{
  Read-only diagnostic for the existing OStim NPC-drinks dialogue route used
  as the structural/condition source by AddMMEExtensionsNewMilkMaidDialogue.
}

const
  TargetPluginName = 'MMEAlert.esp';
  MMEPluginName = 'MilkModNEW.esp';
  SourceEditorID = 'MMEExt_OStimBreastfeeding_NPCDrinks';
  TargetTopicEditorID = 'MMEExt_NewMilkMaidTopic';
  TargetInfoEditorID = 'MMEExt_NewMilkMaid';
  HandlerScriptName = 'MMENewMilkMaid';
  HandlerFragmentName = 'Fragment_CreateMilkMaid';
  PlayerPrompt = 'Wanna become a Milk Maid? Have a taste! Straight from the tap.';
  NPCResponse = 'I''d love a sip! Yummy!';
  SubjectMaidVariable = '::MME_SubjectMaid_var';

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

function DumpWinningOpening(aOpening, aPlayerTopic, aNPCTopic,
  aNewMaidTopic: IInterface): Boolean;
var
  winner, links, linkElement, linkedTopic: IInterface;
  i: Integer;
  hasPlayerTopic, hasNPCTopic, hasNewMaidTopic: Boolean;
begin
  Result := False;
  if not Assigned(aOpening) then begin
    AddMessage('ERROR: MME Hey there opening INFO was not found.');
    Exit;
  end;
  winner := WinningOverride(aOpening);
  AddMessage('OPENING_SOURCE=' + Name(aOpening) + ' file=' +
    GetFileName(GetFile(aOpening)));
  AddMessage('OPENING_WINNER=' + Name(winner) + ' file=' +
    GetFileName(GetFile(winner)));
  links := ElementByName(winner, 'Link To');
  if not Assigned(links) then begin
    AddMessage('ERROR: Winning Hey there INFO has no Link To array.');
    Exit;
  end;
  hasPlayerTopic := False;
  hasNPCTopic := False;
  hasNewMaidTopic := False;
  AddMessage('OPENING_WINNER_LINK_COUNT=' + IntToStr(ElementCount(links)));
  for i := 0 to ElementCount(links) - 1 do begin
    linkElement := ElementByIndex(links, i);
    linkedTopic := LinksTo(linkElement);
    if Assigned(linkedTopic) then begin
      AddMessage('  LINK[' + IntToStr(i) + ']=' + Name(linkedTopic));
      if Assigned(aPlayerTopic) and
         Equals(MasterOrSelf(linkedTopic), MasterOrSelf(aPlayerTopic)) then
        hasPlayerTopic := True;
      if Assigned(aNPCTopic) and
         Equals(MasterOrSelf(linkedTopic), MasterOrSelf(aNPCTopic)) then
        hasNPCTopic := True;
      if Assigned(aNewMaidTopic) and
         Equals(MasterOrSelf(linkedTopic), MasterOrSelf(aNewMaidTopic)) then
        hasNewMaidTopic := True;
    end;
  end;
  if hasPlayerTopic then
    AddMessage('OPENING_HAS_OSTIM_PLAYER=True')
  else
    AddMessage('OPENING_HAS_OSTIM_PLAYER=False');
  if hasNPCTopic then
    AddMessage('OPENING_HAS_OSTIM_NPC=True')
  else
    AddMessage('OPENING_HAS_OSTIM_NPC=False');
  if hasNewMaidTopic then
    AddMessage('OPENING_HAS_NEW_MILK_MAID=True')
  else
    AddMessage('OPENING_HAS_NEW_MILK_MAID=False');
  Result := hasPlayerTopic and hasNPCTopic and hasNewMaidTopic;
  if Result then
    AddMessage('OPENING_REACHABILITY_VALIDATION=PASS')
  else
    AddMessage('OPENING_REACHABILITY_VALIDATION=FAIL');
end;

function ValidateInstalledRoute(aTopic, aInfo: IInterface): Boolean;
var
  topicElement, responses, conditions, condition, vmad: IInterface;
  i, subjectMaidCount: Integer;
begin
  Result := False;
  if not Assigned(aTopic) or not Assigned(aInfo) then begin
    AddMessage('ERROR: Installed Milk Maid route was not found.');
    Exit;
  end;
  topicElement := ElementByName(aInfo, 'Topic');
  responses := ElementByPath(aInfo, 'Responses');
  conditions := ElementByPath(aInfo, 'Conditions');
  vmad := ElementBySignature(aInfo, 'VMAD');
  if not SameText(GetElementEditValues(aTopic, 'FULL'), PlayerPrompt) or
     not SameText(GetElementEditValues(aInfo, 'RNAM'), PlayerPrompt) or
     not Assigned(topicElement) or not Assigned(LinksTo(topicElement)) or
     not Equals(MasterOrSelf(LinksTo(topicElement)), MasterOrSelf(aTopic)) or
     not Assigned(responses) or (ElementCount(responses) <> 1) or
     not SameText(GetElementEditValues(ElementByIndex(responses, 0), 'NAM1'),
       NPCResponse) or
     not Assigned(conditions) or (ElementCount(conditions) <> 7) or
     not Assigned(vmad) or not TreeHasExactValue(vmad, HandlerScriptName) or
     not TreeHasExactValue(vmad, HandlerFragmentName) then begin
    AddMessage('ERROR: Installed Milk Maid route failed structural validation.');
    Exit;
  end;

  subjectMaidCount := 0;
  for i := 0 to ElementCount(conditions) - 1 do begin
    condition := ElementByIndex(conditions, i);
    if SameText(GetElementEditValues(condition, 'CIS2'),
        SubjectMaidVariable) and
       (GetElementNativeValues(condition,
        'CTDA\Comparison Value - Float') = 0.0) then
      Inc(subjectMaidCount);
  end;
  if subjectMaidCount <> 1 then begin
    AddMessage('ERROR: Installed route does not contain exactly one inverted SubjectMaid gate.');
    Exit;
  end;
  if (Check(aTopic) <> '') or (Check(aInfo) <> '') then begin
    AddMessage('ERROR: xEdit reports an error on the installed topic or INFO.');
    Exit;
  end;
  AddMessage('INSTALLED_TOPIC=' + Name(aTopic));
  AddMessage('INSTALLED_INFO=' + Name(aInfo));
  AddMessage('INSTALLED_ROUTE_VALIDATION=PASS');
  Result := True;
end;

function FindRecordRecursive(aElement: IInterface;
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
    Result := FindRecordRecursive(ElementByIndex(aElement, i),
      aSignature, aEditorID);
    if Assigned(Result) then
      Exit;
  end;
end;

procedure DumpTree(aElement: IInterface; aIndent: string);
var
  i: Integer;
begin
  if not Assigned(aElement) then
    Exit;
  AddMessage(aIndent + Name(aElement) + ' = ' + GetEditValue(aElement));
  for i := 0 to ElementCount(aElement) - 1 do
    DumpTree(ElementByIndex(aElement, i), aIndent + '  ');
end;

procedure FindSubjectMaidConditions(aElement: IInterface);
var
  i, j: Integer;
  conditions, condition: IInterface;
begin
  if not Assigned(aElement) then
    Exit;
  if Signature(aElement) = 'INFO' then begin
    conditions := ElementByPath(aElement, 'Conditions');
    if Assigned(conditions) then
      for j := 0 to ElementCount(conditions) - 1 do begin
        condition := ElementByIndex(conditions, j);
        if SameText(GetElementEditValues(condition, 'CIS2'),
            SubjectMaidVariable) then begin
          AddMessage('SUBJECT_MAID_SOURCE=' + Name(aElement));
          DumpTree(condition, '  ');
        end;
      end;
  end;
  for i := 0 to ElementCount(aElement) - 1 do
    FindSubjectMaidConditions(ElementByIndex(aElement, i));
end;

function Initialize: Integer;
var
  targetFile, mmeFile, sourceInfo, targetTopic, targetInfo,
    playerTopic, npcTopic, openingInfo: IInterface;
begin
  Result := 1;
  targetFile := FindFileByName(TargetPluginName);
  mmeFile := FindFileByName(MMEPluginName);
  if not Assigned(targetFile) or not Assigned(mmeFile) then begin
    AddMessage('ERROR: Required plugins were not loaded.');
    Exit;
  end;
  sourceInfo := FindRecordRecursive(GroupBySignature(targetFile, 'DIAL'),
    'INFO', SourceEditorID);
  if not Assigned(sourceInfo) then begin
    AddMessage('ERROR: ' + SourceEditorID + ' was not found.');
    Exit;
  end;
  AddMessage('SOURCE=' + Name(sourceInfo));
  DumpTree(sourceInfo, '');
  FindSubjectMaidConditions(GroupBySignature(mmeFile, 'DIAL'));
  targetTopic := FindRecordRecursive(GroupBySignature(targetFile, 'DIAL'),
    'DIAL', TargetTopicEditorID);
  targetInfo := FindRecordRecursive(GroupBySignature(targetFile, 'DIAL'),
    'INFO', TargetInfoEditorID);
  if not ValidateInstalledRoute(targetTopic, targetInfo) then
    Exit;
  playerTopic := FindRecordRecursive(GroupBySignature(targetFile, 'DIAL'),
    'DIAL', 'MMEExt_OStimBreastfeeding_PlayerDrinksTopic');
  npcTopic := FindRecordRecursive(GroupBySignature(targetFile, 'DIAL'),
    'DIAL', 'MMEExt_OStimBreastfeeding_NPCDrinksTopic');
  openingInfo := FindOpeningInfo(GroupBySignature(mmeFile, 'DIAL'));
  if not DumpWinningOpening(openingInfo, playerTopic, npcTopic,
    targetTopic) then
    Exit;
  Result := 0;
end;

end.
