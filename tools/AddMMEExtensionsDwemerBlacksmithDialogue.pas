unit UserScript;

{
  Adds reversible Dwemer-attachment choices beneath MME's existing
  [MME] Hey there! opening. Safe to rerun by stable EditorID.
}

const
  TargetPluginName = 'MMEAlert.esp';
  OpeningTopicEditorID = 'MME_Hello_Dialogue_Topic';
  DonorTopicEditorID = 'MMEExt_MageRemoveParasiteArmorTopic';
  DonorInfoEditorID = 'MMEExt_MageRemoveParasiteArmor';
  DonorGlobalEditorID = 'MMEExt_MageParasiteArmorState';
  StateGlobalEditorID = 'MMEExt_DwemerBlacksmithArmorState';
  StatePropertyName = 'MMEExt_DwemerBlacksmithArmorState';
  HandlerScriptName = 'MMEBlacksmithDialogue';
  OpeningFragmentName = 'Fragment_RefreshBlacksmithArmorState';
  DonorFragmentName = 'Fragment_RemoveParasiteArmor';

var
  TargetFile, OpeningTopic, OpeningInfo, DonorTopic, DonorInfo: IInterface;
  DonorGlobal, StateGlobal: IInterface;

function FindFileByName(aName: string): IInterface;
var i: Integer;
begin
  Result := nil;
  for i := 0 to FileCount - 1 do
    if SameText(GetFileName(FileByIndex(i)), aName) then begin
      Result := FileByIndex(i); Exit;
    end;
end;

function FindRecord(aElement: IInterface; aSignature, aEditorID: string): IInterface;
var i: Integer;
begin
  Result := nil;
  if not Assigned(aElement) then Exit;
  if (Signature(aElement) = aSignature) and SameText(EditorID(aElement), aEditorID) then begin
    Result := aElement; Exit;
  end;
  for i := 0 to ElementCount(aElement) - 1 do begin
    Result := FindRecord(ElementByIndex(aElement, i), aSignature, aEditorID);
    if Assigned(Result) then Exit;
  end;
end;

function TreeHasValue(aElement: IInterface; aValue: string): Boolean;
var i: Integer;
begin
  Result := False;
  if not Assigned(aElement) then Exit;
  if SameText(GetEditValue(aElement), aValue) then begin Result := True; Exit; end;
  for i := 0 to ElementCount(aElement) - 1 do
    if TreeHasValue(ElementByIndex(aElement, i), aValue) then begin Result := True; Exit; end;
end;

procedure ReplaceTreeValue(aElement: IInterface; aOld, aNew: string);
var i: Integer;
begin
  if not Assigned(aElement) then Exit;
  if SameText(GetEditValue(aElement), aOld) then SetEditValue(aElement, aNew);
  for i := 0 to ElementCount(aElement) - 1 do ReplaceTreeValue(ElementByIndex(aElement, i), aOld, aNew);
end;

function FindOpeningInfo(aTopic: IInterface): IInterface;
var children, candidate, vmad: IInterface; i: Integer;
begin
  Result := nil; children := ChildGroup(aTopic);
  for i := 0 to ElementCount(children) - 1 do begin
    candidate := ElementByIndex(children, i);
    if Signature(candidate) = 'INFO' then begin
      vmad := ElementBySignature(candidate, 'VMAD');
      if TreeHasValue(vmad, OpeningFragmentName) then begin Result := candidate; Exit; end;
    end;
  end;
end;

function FindScript(aVmad: IInterface; aName: string): IInterface;
var scripts, entry: IInterface; i: Integer;
begin
  Result := nil; scripts := ElementByPath(aVmad, 'Scripts');
  for i := 0 to ElementCount(scripts) - 1 do begin
    entry := ElementByIndex(scripts, i);
    if SameText(GetElementEditValues(entry, 'ScriptName'), aName) then begin Result := entry; Exit; end;
  end;
end;

function FindProperty(aScript: IInterface; aName: string): IInterface;
var props, entry: IInterface; i: Integer;
begin
  Result := nil; props := ElementByPath(aScript, 'Properties');
  for i := 0 to ElementCount(props) - 1 do begin
    entry := ElementByIndex(props, i);
    if SameText(GetElementEditValues(entry, 'propertyName'), aName) then begin Result := entry; Exit; end;
  end;
end;

function EnsureStateGlobal: Boolean;
begin
  StateGlobal := FindRecord(GroupBySignature(TargetFile, 'GLOB'), 'GLOB', StateGlobalEditorID);
  if not Assigned(StateGlobal) then begin
    StateGlobal := wbCopyElementToFile(DonorGlobal, TargetFile, True, True);
    if Assigned(StateGlobal) then SetEditorID(StateGlobal, StateGlobalEditorID);
  end;
  Result := Assigned(StateGlobal);
  if Result then SetElementNativeValues(StateGlobal, 'FLTV', 0.0);
end;

function EnsureOpeningProperty: Boolean;
var vmad, scriptEntry, props, prop, donorProp, formField: IInterface;
begin
  Result := False; vmad := ElementBySignature(OpeningInfo, 'VMAD');
  scriptEntry := FindScript(vmad, HandlerScriptName);
  if not Assigned(scriptEntry) then Exit;
  prop := FindProperty(scriptEntry, StatePropertyName);
  if not Assigned(prop) then begin
    donorProp := FindProperty(scriptEntry, 'MMEExt_MageParasiteArmorState');
    props := ElementByPath(scriptEntry, 'Properties');
    if not Assigned(donorProp) or not Assigned(props) then Exit;
    prop := ElementAssign(props, HighInteger, donorProp, False);
    SetElementEditValues(prop, 'propertyName', StatePropertyName);
  end;
  formField := ElementByPath(prop, 'Value\Object Union\Object v2\FormID');
  SetEditValue(formField, Name(StateGlobal));
  Result := Assigned(LinksTo(formField)) and Equals(MasterOrSelf(LinksTo(formField)), MasterOrSelf(StateGlobal));
end;

function EnsureChoice(aTopicID, aInfoID, aPrompt, aResponse, aFragment: string; aState: Float): Boolean;
var topic, info, children, topicField, rows, sourceRows, row, donorConditions,
    donorCondition, conditions, newCondition, parameter, vmad: IInterface; i: Integer;
begin
  Result := False;
  topic := FindRecord(GroupBySignature(TargetFile, 'DIAL'), 'DIAL', aTopicID);
  if not Assigned(topic) then begin
    topic := wbCopyElementToFile(DonorTopic, TargetFile, True, True);
    if not Assigned(topic) then Exit;
    children := ChildGroup(topic);
    for i := ElementCount(children) - 1 downto 0 do
      if Signature(ElementByIndex(children, i)) = 'INFO' then Remove(ElementByIndex(children, i));
  end;
  SetEditorID(topic, aTopicID); SetElementEditValues(topic, 'FULL', aPrompt);

  info := FindRecord(GroupBySignature(TargetFile, 'DIAL'), 'INFO', aInfoID);
  if not Assigned(info) then info := wbCopyElementToFile(DonorInfo, TargetFile, True, True);
  if not Assigned(info) then Exit;
  SetEditorID(info, aInfoID);
  topicField := ElementByName(info, 'Topic'); SetEditValue(topicField, Name(topic));
  SetElementEditValues(info, 'RNAM', aPrompt);
  if Assigned(ElementBySignature(info, 'PNAM')) then Remove(ElementBySignature(info, 'PNAM'));
  if Assigned(ElementByName(info, 'Link To')) then Remove(ElementByName(info, 'Link To'));

  sourceRows := ElementByPath(DonorInfo, 'Responses'); rows := ElementByPath(info, 'Responses');
  if Assigned(rows) then Remove(rows); Add(info, 'Responses', True); rows := ElementByPath(info, 'Responses');
  row := ElementAssign(rows, HighInteger, ElementByIndex(sourceRows, 0), False);
  if not Assigned(row) then Exit; SetElementEditValues(row, 'NAM1', aResponse);

  donorConditions := ElementByPath(DonorInfo, 'Conditions'); donorCondition := nil;
  for i := 0 to ElementCount(donorConditions) - 1 do
    if SameText(GetElementEditValues(ElementByIndex(donorConditions, i), 'CTDA\Function'), 'GetGlobalValue') then
      donorCondition := ElementByIndex(donorConditions, i);
  if not Assigned(donorCondition) then Exit;
  conditions := ElementByPath(info, 'Conditions'); if Assigned(conditions) then Remove(conditions);
  Add(info, 'Conditions', True); conditions := ElementByPath(info, 'Conditions');
  newCondition := ElementAssign(conditions, HighInteger, donorCondition, False);
  parameter := ElementByPath(newCondition, 'CTDA\Parameter #1'); SetEditValue(parameter, Name(StateGlobal));
  SetElementNativeValues(newCondition, 'CTDA\Comparison Value - Float', aState);
  SetElementNativeValues(newCondition, 'CTDA\Type', 0);

  vmad := ElementBySignature(info, 'VMAD'); ReplaceTreeValue(vmad, DonorFragmentName, aFragment);
  if not TreeHasValue(vmad, HandlerScriptName) or not TreeHasValue(vmad, aFragment) then Exit;

  if not TreeHasValue(ElementByName(OpeningInfo, 'Link To'), Name(topic)) then begin
    rows := ElementByName(OpeningInfo, 'Link To');
    row := ElementAssign(rows, HighInteger, ElementByIndex(rows, ElementCount(rows) - 1), False);
    SetEditValue(row, Name(topic));
  end;
  Result := TreeHasValue(ElementByName(OpeningInfo, 'Link To'), Name(topic));
end;

function Initialize: Integer;
begin
  Result := 1; AddMessage('MME Extensions Dwemer blacksmith dialogue installer.');
  TargetFile := FindFileByName(TargetPluginName);
  if not Assigned(TargetFile) then begin AddMessage('ERROR: Load MMEAlert.esp.'); Exit; end;
  OpeningTopic := FindRecord(GroupBySignature(TargetFile, 'DIAL'), 'DIAL', OpeningTopicEditorID);
  DonorTopic := FindRecord(GroupBySignature(TargetFile, 'DIAL'), 'DIAL', DonorTopicEditorID);
  DonorInfo := FindRecord(GroupBySignature(TargetFile, 'DIAL'), 'INFO', DonorInfoEditorID);
  DonorGlobal := FindRecord(GroupBySignature(TargetFile, 'GLOB'), 'GLOB', DonorGlobalEditorID);
  if not Assigned(OpeningTopic) or not Assigned(DonorTopic) or not Assigned(DonorInfo) or not Assigned(DonorGlobal) then begin
    AddMessage('ERROR: Existing dialogue templates are missing.'); Exit;
  end;
  OpeningInfo := FindOpeningInfo(OpeningTopic);
  if not Assigned(OpeningInfo) then begin AddMessage('ERROR: Wrapped Hey there opening INFO not found.'); Exit; end;
  if not EnsureStateGlobal or not EnsureOpeningProperty then begin AddMessage('ERROR: State setup failed.'); Exit; end;
  if not EnsureChoice('MMEExt_DwemerBlacksmithInstallTopic', 'MMEExt_DwemerBlacksmithInstall',
      'I want a kinky milking attachment fitted inside my armor. Something that''ll tease me until I scream.',
      'Damn, girl! Finally, a customer with ambition. I''ve got just the contraption for you.',
      'Fragment_InstallDwemerAttachment', 1.0) then begin AddMessage('ERROR: Install choice failed.'); Exit; end;
  if not EnsureChoice('MMEExt_DwemerBlacksmithRemoveTopic', 'MMEExt_DwemerBlacksmithRemove',
      'Remember that kinky milking contraption? I''ve reconsidered my ambitions.',
      'Ha! I was wondering when you''d be back. Hold still, I''ll save it for the next brave volunteer.',
      'Fragment_RemoveDwemerAttachment', 2.0) then begin AddMessage('ERROR: Removal choice failed.'); Exit; end;
  AddMessage('Installed both Dwemer blacksmith choices. Save MMEAlert.esp and run Check for Errors.');
  Result := 0;
end;

end.
