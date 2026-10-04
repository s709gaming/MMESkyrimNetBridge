unit UserScript;

{
  Adds one professional timed-trap-armor removal choice beneath MME's existing
  [MME] Hey there! opening. Safe to rerun by stable EditorID.

  Run with Skyrim.esm, MilkModNEW.esp, MMEAlert.esp, and every plugin touching
  MME_Hello_Dialogue_Topic loaded. MMEAlert.esp must be the winning override.
}

const
  TargetPluginName = 'MMEAlert.esp';
  OpeningTopicEditorID = 'MME_Hello_Dialogue_Topic';
  DonorTopicEditorID = 'MMEExt_MageRemoveParasiteArmorTopic';
  DonorInfoEditorID = 'MMEExt_MageRemoveParasiteArmor';
  DonorGlobalEditorID = 'MMEExt_MageParasiteArmorState';
  StateGlobalEditorID = 'MMEExt_TrapArmorRemovalState';
  TopicEditorID = 'MMEExt_TrapArmorRemovalTopic';
  InfoEditorID = 'MMEExt_TrapArmorRemoval';
  HandlerScriptName = 'MMEBlacksmithDialogue';
  StatePropertyName = 'MMEExt_TrapArmorRemovalState';
  OpeningFragmentName = 'Fragment_RefreshBlacksmithArmorState';
  DonorFragmentName = 'Fragment_RemoveParasiteArmor';
  ActionFragmentName = 'Fragment_RemoveTimedTrapArmor';
  PlayerPrompt = 'I''m stuck. Can you help get this off me?';
  NPCResponse = 'Oh, look at you. Thoroughly defeated by your own wardrobe. Hold still, I''ll tease it off.';

var
  TargetFile, OpeningTopic, OpeningInfo, DonorTopic, DonorInfo: IInterface;
  DonorGlobal, StateGlobal, NewTopic, NewInfo: IInterface;

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

function FindRecord(aElement: IInterface; aSignature, aEditorID: string): IInterface;
var i: Integer;
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

function TreeHasValue(aElement: IInterface; aValue: string): Boolean;
var i: Integer;
begin
  Result := False;
  if not Assigned(aElement) then Exit;
  if SameText(GetEditValue(aElement), aValue) then begin
    Result := True;
    Exit;
  end;
  for i := 0 to ElementCount(aElement) - 1 do
    if TreeHasValue(ElementByIndex(aElement, i), aValue) then begin
      Result := True;
      Exit;
    end;
end;

procedure ReplaceTreeValue(aElement: IInterface; aOld, aNew: string);
var i: Integer;
begin
  if not Assigned(aElement) then Exit;
  if SameText(GetEditValue(aElement), aOld) then
    SetEditValue(aElement, aNew);
  for i := 0 to ElementCount(aElement) - 1 do
    ReplaceTreeValue(ElementByIndex(aElement, i), aOld, aNew);
end;

function FindOpeningInfo(aTopic: IInterface): IInterface;
var children, candidate, vmad: IInterface; i: Integer;
begin
  Result := nil;
  children := ChildGroup(aTopic);
  for i := 0 to ElementCount(children) - 1 do begin
    candidate := ElementByIndex(children, i);
    if Signature(candidate) = 'INFO' then begin
      vmad := ElementBySignature(candidate, 'VMAD');
      if TreeHasValue(vmad, OpeningFragmentName) then begin
        Result := candidate;
        Exit;
      end;
    end;
  end;
end;

function FindScript(aVmad: IInterface; aName: string): IInterface;
var scripts, entry: IInterface; i: Integer;
begin
  Result := nil;
  scripts := ElementByPath(aVmad, 'Scripts');
  for i := 0 to ElementCount(scripts) - 1 do begin
    entry := ElementByIndex(scripts, i);
    if SameText(GetElementEditValues(entry, 'ScriptName'), aName) then begin
      Result := entry;
      Exit;
    end;
  end;
end;

function FindProperty(aScript: IInterface; aName: string): IInterface;
var props, entry: IInterface; i: Integer;
begin
  Result := nil;
  props := ElementByPath(aScript, 'Properties');
  for i := 0 to ElementCount(props) - 1 do begin
    entry := ElementByIndex(props, i);
    if SameText(GetElementEditValues(entry, 'propertyName'), aName) then begin
      Result := entry;
      Exit;
    end;
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
  Result := False;
  vmad := ElementBySignature(OpeningInfo, 'VMAD');
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

function EnsureTopic: Boolean;
var children: IInterface; i: Integer;
begin
  NewTopic := FindRecord(GroupBySignature(TargetFile, 'DIAL'), 'DIAL', TopicEditorID);
  if not Assigned(NewTopic) then begin
    NewTopic := wbCopyElementToFile(DonorTopic, TargetFile, True, True);
    if not Assigned(NewTopic) then begin Result := False; Exit; end;
    children := ChildGroup(NewTopic);
    for i := ElementCount(children) - 1 downto 0 do
      if Signature(ElementByIndex(children, i)) = 'INFO' then Remove(ElementByIndex(children, i));
  end;
  SetEditorID(NewTopic, TopicEditorID);
  SetElementEditValues(NewTopic, 'FULL', PlayerPrompt);
  Result := True;
end;

function RebuildResponse(aInfo: IInterface): Boolean;
var sourceRows, rows, row: IInterface;
begin
  Result := False;
  sourceRows := ElementByPath(DonorInfo, 'Responses');
  rows := ElementByPath(aInfo, 'Responses');
  if Assigned(rows) then Remove(rows);
  Add(aInfo, 'Responses', True);
  rows := ElementByPath(aInfo, 'Responses');
  row := ElementAssign(rows, HighInteger, ElementByIndex(sourceRows, 0), False);
  if not Assigned(row) then Exit;
  SetElementEditValues(row, 'NAM1', NPCResponse);
  Result := True;
end;

function RebuildConditions(aInfo: IInterface): Boolean;
var donorConditions, conditions, donorCondition, newCondition, parameter: IInterface;
    i: Integer;
begin
  Result := False;
  donorConditions := ElementByPath(DonorInfo, 'Conditions');
  donorCondition := nil;
  for i := 0 to ElementCount(donorConditions) - 1 do
    if SameText(GetElementEditValues(ElementByIndex(donorConditions, i), 'CTDA\Function'), 'GetGlobalValue') then
      donorCondition := ElementByIndex(donorConditions, i);
  if not Assigned(donorCondition) then Exit;
  conditions := ElementByPath(aInfo, 'Conditions');
  if Assigned(conditions) then Remove(conditions);
  Add(aInfo, 'Conditions', True);
  conditions := ElementByPath(aInfo, 'Conditions');
  newCondition := ElementAssign(conditions, HighInteger, donorCondition, False);
  if not Assigned(newCondition) then Exit;
  parameter := ElementByPath(newCondition, 'CTDA\Parameter #1');
  SetEditValue(parameter, Name(StateGlobal));
  SetElementNativeValues(newCondition, 'CTDA\Comparison Value - Float', 1.0);
  SetElementNativeValues(newCondition, 'CTDA\Type', 0);
  Result := Assigned(LinksTo(parameter)) and Equals(MasterOrSelf(LinksTo(parameter)), MasterOrSelf(StateGlobal));
end;

function RebuildInfo: Boolean;
var topicField, vmad, links, previous: IInterface;
begin
  Result := False;
  NewInfo := FindRecord(GroupBySignature(TargetFile, 'DIAL'), 'INFO', InfoEditorID);
  if not Assigned(NewInfo) then NewInfo := wbCopyElementToFile(DonorInfo, TargetFile, True, True);
  if not Assigned(NewInfo) then Exit;
  SetEditorID(NewInfo, InfoEditorID);
  topicField := ElementByName(NewInfo, 'Topic');
  SetEditValue(topicField, Name(NewTopic));
  SetElementEditValues(NewInfo, 'RNAM', PlayerPrompt);
  previous := ElementBySignature(NewInfo, 'PNAM');
  if Assigned(previous) then Remove(previous);
  links := ElementByName(NewInfo, 'Link To');
  if Assigned(links) then Remove(links);
  if not RebuildResponse(NewInfo) or not RebuildConditions(NewInfo) then Exit;
  vmad := ElementBySignature(NewInfo, 'VMAD');
  ReplaceTreeValue(vmad, DonorFragmentName, ActionFragmentName);
  Result := TreeHasValue(vmad, HandlerScriptName) and TreeHasValue(vmad, ActionFragmentName);
end;

function EnsureOpeningLink: Boolean;
var links, entry, template: IInterface; i: Integer;
begin
  Result := False;
  links := ElementByName(OpeningInfo, 'Link To');
  for i := 0 to ElementCount(links) - 1 do
    if Assigned(LinksTo(ElementByIndex(links, i))) and
       Equals(MasterOrSelf(LinksTo(ElementByIndex(links, i))), MasterOrSelf(NewTopic)) then begin
      Result := True;
      Exit;
    end;
  template := ElementByIndex(links, ElementCount(links) - 1);
  entry := ElementAssign(links, HighInteger, template, False);
  SetEditValue(entry, Name(NewTopic));
  Result := Assigned(LinksTo(entry)) and Equals(MasterOrSelf(LinksTo(entry)), MasterOrSelf(NewTopic));
end;

function Initialize: Integer;
begin
  Result := 1;
  AddMessage('MME Extensions trap armor vendor dialogue installer.');
  TargetFile := FindFileByName(TargetPluginName);
  if not Assigned(TargetFile) then begin AddMessage('ERROR: Load MMEAlert.esp.'); Exit; end;
  OpeningTopic := FindRecord(GroupBySignature(TargetFile, 'DIAL'), 'DIAL', OpeningTopicEditorID);
  DonorTopic := FindRecord(GroupBySignature(TargetFile, 'DIAL'), 'DIAL', DonorTopicEditorID);
  DonorInfo := FindRecord(GroupBySignature(TargetFile, 'DIAL'), 'INFO', DonorInfoEditorID);
  DonorGlobal := FindRecord(GroupBySignature(TargetFile, 'GLOB'), 'GLOB', DonorGlobalEditorID);
  if not Assigned(OpeningTopic) or not Assigned(DonorTopic) or not Assigned(DonorInfo) or not Assigned(DonorGlobal) then begin
    AddMessage('ERROR: Existing MME Extensions dialogue templates are missing.'); Exit;
  end;
  OpeningInfo := FindOpeningInfo(OpeningTopic);
  if not Assigned(OpeningInfo) then begin AddMessage('ERROR: Wrapped Hey there opening INFO not found.'); Exit; end;
  if not EnsureStateGlobal or not EnsureOpeningProperty or not EnsureTopic or not RebuildInfo or not EnsureOpeningLink then begin
    AddMessage('ERROR: Construction failed. Discard unsaved changes.'); Exit;
  end;
  AddMessage('Installed: ' + PlayerPrompt);
  AddMessage('Response: ' + NPCResponse);
  AddMessage('Save MMEAlert.esp and run Check for Errors.');
  Result := 0;
end;

end.
