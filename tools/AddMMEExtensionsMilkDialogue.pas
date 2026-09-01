unit UserScript;

{
  Milk-giving dialogue installer for MME Extensions.

  Adds one new player response beneath the same MME dialogue topic used by
  MME_Dialogues.Fragment_03 (MME's existing give-Lactacid response). The
  source INFO is copied as a new record so its dialogue routing is retained.
  Its conditions are replaced by only the supported
  Lactacid/normal/racial/special milk inventory OR group. The source INFO's
  sex, race, relationship, and Milk Maid restrictions do not apply: any NPC
  can offer the dialogue while the player has a supported milk item.

  Required loaded files:
    Skyrim.esm
    HearthFires.esm
    MilkModNEW.esp
    MMEAlert.esp

  Safe to rerun: an existing MMEExt_DialogueDrinkMilk INFO is updated in place.
}

const
  TargetPluginName = 'MMEAlert.esp';
  MMEPluginName = 'MilkModNEW.esp';
  SkyrimPluginName = 'Skyrim.esm';
  HearthFiresPluginName = 'HearthFires.esm';
  HearthFiresMilkEditorID = 'BYOHFoodMilk';
  BasicMilkListEditorID = 'MME_Milk_Basic';
  RaceMilkListEditorID = 'MME_Milk_Race_Normal';
  SpecialMilkListEditorID = 'MME_Milk_Special';
  HearthFiresMilkFormID = $00003534;
  BasicMilkListFormID = $0005E87B;
  RaceMilkListFormID = $00071C2B;
  SpecialMilkListFormID = $00071C2D;
  NewInfoEditorID = 'MMEExt_DialogueDrinkMilk';
  PlayerPrompt = 'I''d love some. Bet I know where that came from!';
  NPCResponse = 'Would you like to drink some milk?';
  CopiedUnwantedResponse = 'I hope you will give me some good milking soon!';

var
  TargetFile, MMEFile, SkyrimFile, HearthFiresFile, SourceInfo: IInterface;
  SourceMatches: Integer;

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

function ResolveSupportedMilkRecord(aFile: IInterface; aSignature,
  aEditorID: string; aLocalFormID: Cardinal): IInterface;
begin
  Result := FindRecordByEditorIDRecursive(GroupBySignature(aFile, aSignature),
    aSignature, aEditorID);

  // These local IDs were verified against the supported local MME/HearthFires
  // records. They are only a fallback for xEdit builds whose recursive group
  // traversal does not expose the record to JvInterpreter.
  if not Assigned(Result) then begin
    Result := RecordByFormID(aFile, aLocalFormID, True);
    if Assigned(Result) and
       ((Signature(Result) <> aSignature) or
        not SameText(EditorID(Result), aEditorID)) then
      Result := nil;
  end;

  if Assigned(Result) then
    AddMessage('Resolved supported milk form: ' + Name(Result))
  else
    AddMessage('ERROR: Could not resolve ' + aEditorID + ' [' +
      aSignature + ':' + IntToHex(aLocalFormID, 8) + '] from ' +
      GetFileName(aFile) + '.');
end;

function AddSupportedMilkCondition(aConditions, aTemplate,
  aItem: IInterface; aUseOr: Boolean): Boolean;
var
  newCondition: IInterface;
  conditionType: Integer;
begin
  Result := False;
  if not Assigned(aConditions) or not Assigned(aTemplate) or
     not Assigned(aItem) then
    Exit;
  AddRequiredElementMasters(aItem, TargetFile, False);
  newCondition := ElementAssign(aConditions, HighInteger, aTemplate, False);
  if not Assigned(newCondition) then
    Exit;
  SetEditValue(ElementByPath(newCondition, 'CTDA\Parameter #1'), Name(aItem));
  conditionType := GetElementNativeValues(newCondition, 'CTDA\Type');
  if aUseOr then
    conditionType := conditionType or 1
  else
    conditionType := conditionType and $FE;
  SetElementNativeValues(newCondition, 'CTDA\Type', conditionType);
  Result := SameText(GetElementEditValues(newCondition, 'CTDA\Function'),
      'GetItemCount') and
    Equals(MasterOrSelf(LinksTo(ElementByPath(newCondition,
      'CTDA\Parameter #1'))), MasterOrSelf(aItem));
end;

function RebuildSupportedMilkConditions(aInfo, aSourceInfo: IInterface): Boolean;
var
  sourceConditions, targetConditions, sourceCondition,
    inventoryTemplate, hearthMilk, basicMilk, raceMilk,
    specialMilk: IInterface;
  i, inventoryCount: Integer;
begin
  Result := False;
  sourceConditions := ElementByPath(aSourceInfo, 'Conditions');
  if not Assigned(sourceConditions) then begin
    AddMessage('ERROR: Source INFO has no conditions.');
    Exit;
  end;

  inventoryTemplate := nil;
  inventoryCount := 0;
  for i := 0 to ElementCount(sourceConditions) - 1 do begin
    sourceCondition := ElementByIndex(sourceConditions, i);
    if SameText(GetElementEditValues(sourceCondition, 'CTDA\Function'),
        'GetItemCount') then begin
      Inc(inventoryCount);
      inventoryTemplate := sourceCondition;
    end;
  end;
  if (inventoryCount <> 1) or not Assigned(inventoryTemplate) then begin
    AddMessage('ERROR: Expected one source GetItemCount condition; found ' +
      IntToStr(inventoryCount) + '.');
    Exit;
  end;

  hearthMilk := ResolveSupportedMilkRecord(HearthFiresFile, 'ALCH',
    HearthFiresMilkEditorID, HearthFiresMilkFormID);
  basicMilk := ResolveSupportedMilkRecord(MMEFile, 'FLST',
    BasicMilkListEditorID, BasicMilkListFormID);
  raceMilk := ResolveSupportedMilkRecord(MMEFile, 'FLST',
    RaceMilkListEditorID, RaceMilkListFormID);
  specialMilk := ResolveSupportedMilkRecord(MMEFile, 'FLST',
    SpecialMilkListEditorID, SpecialMilkListFormID);
  if not Assigned(hearthMilk) or not Assigned(basicMilk) or
     not Assigned(raceMilk) or not Assigned(specialMilk) then begin
    AddMessage('ERROR: One or more authoritative supported-milk forms are missing.');
    Exit;
  end;

  targetConditions := ElementByPath(aInfo, 'Conditions');
  if Assigned(targetConditions) then
    Remove(targetConditions);
  Add(aInfo, 'Conditions', True);
  targetConditions := ElementByPath(aInfo, 'Conditions');
  if not Assigned(targetConditions) then
    Exit;

  if not AddSupportedMilkCondition(targetConditions, inventoryTemplate,
      LinksTo(ElementByPath(inventoryTemplate, 'CTDA\Parameter #1')), True) or
     not AddSupportedMilkCondition(targetConditions, inventoryTemplate,
      hearthMilk, True) or
     not AddSupportedMilkCondition(targetConditions, inventoryTemplate,
      basicMilk, True) or
     not AddSupportedMilkCondition(targetConditions, inventoryTemplate,
      raceMilk, True) or
     not AddSupportedMilkCondition(targetConditions, inventoryTemplate,
      specialMilk, True) then begin
    AddMessage('ERROR: Supported-milk inventory OR group could not be built.');
    Exit;
  end;

  // Do not copy the source INFO's actor eligibility conditions. They belong
  // to MME's original Milk Maid dialogue and unnecessarily restrict which
  // NPC can offer this option. The inventory OR group is the only condition
  // needed here: Fragment_0 validates and consumes the selected milk at
  // runtime.
  Result := ElementCount(targetConditions) = 5;
  if Result then
    AddMessage('Inventory eligibility: Lactacid OR HearthFires milk OR ' +
      BasicMilkListEditorID + ' OR ' + RaceMilkListEditorID + ' OR ' +
      SpecialMilkListEditorID + '.');
end;

function TreeContains(aElement: IInterface; aNeedle: string): Boolean;
var
  i: Integer;
begin
  Result := False;
  if not Assigned(aElement) then
    Exit;

  if Pos(UpperCase(aNeedle), UpperCase(Name(aElement))) > 0 then begin
    Result := True;
    Exit;
  end;
  if Pos(UpperCase(aNeedle), UpperCase(GetEditValue(aElement))) > 0 then begin
    Result := True;
    Exit;
  end;

  for i := 0 to ElementCount(aElement) - 1 do
    if TreeContains(ElementByIndex(aElement, i), aNeedle) then begin
      Result := True;
      Exit;
    end;
end;

procedure FindSourceInfoRecursive(aElement: IInterface);
var
  i: Integer;
  vmad: IInterface;
begin
  if not Assigned(aElement) then
    Exit;

  if Signature(aElement) = 'INFO' then begin
    vmad := ElementBySignature(aElement, 'VMAD');
    if Assigned(vmad) and
       TreeContains(vmad, 'MME_Dialogues') and
       TreeContains(vmad, 'Fragment_03') then begin
      Inc(SourceMatches);
      SourceInfo := aElement;
    end;
  end;

  for i := 0 to ElementCount(aElement) - 1 do
    FindSourceInfoRecursive(ElementByIndex(aElement, i));
end;

function ConfigureResponses(aInfo: IInterface): Boolean;
var
  responses, response: IInterface;
  i, unwantedIndex, unwantedCount: Integer;
  responseText: string;
begin
  Result := False;
  responses := ElementByPath(aInfo, 'Responses');
  if not Assigned(responses) or (ElementCount(responses) = 0) then
    Exit;

  AddMessage('INFO currently has ' + IntToStr(ElementCount(responses)) +
    ' response(s).');
  unwantedIndex := -1;
  unwantedCount := 0;
  for i := 0 to ElementCount(responses) - 1 do begin
    response := ElementByIndex(responses, i);
    responseText := GetElementEditValues(response, 'NAM1');
    AddMessage('  Response ' + IntToStr(i) + ': ' + responseText);
    if SameText(responseText, CopiedUnwantedResponse) then begin
      unwantedIndex := i;
      Inc(unwantedCount);
    end;
  end;

  // The copied MME source has exactly two responses. A previously repaired
  // INFO has one. Refuse any other shape instead of deleting by position.
  if (ElementCount(responses) > 2) or (unwantedCount > 1) or
     ((ElementCount(responses) = 2) and (unwantedCount <> 1)) then begin
    AddMessage('ERROR: Response structure is ambiguous; no response was removed.');
    Exit;
  end;
  if (ElementCount(responses) = 1) and (unwantedCount <> 0) then begin
    AddMessage('ERROR: The only response is the unwanted copied line; aborting.');
    Exit;
  end;

  if unwantedCount = 1 then begin
    Remove(ElementByIndex(responses, unwantedIndex));
    AddMessage('Removed copied response: ' + CopiedUnwantedResponse);
  end;
  if ElementCount(responses) <> 1 then
    Exit;

  response := ElementByIndex(responses, 0);
  SetElementEditValues(response, 'NAM1', NPCResponse);
  Result := SameText(GetElementEditValues(response, 'NAM1'), NPCResponse);
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

function InstallTestFragment(aInfo, aSourceInfo: IInterface): Boolean;
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

  ReplaceTreeValue(targetVmad, 'MME_Dialogues', 'MMENPCDialog');
  ReplaceTreeValue(targetVmad, 'Fragment_03', 'Fragment_0');
  Result := TreeContains(targetVmad, 'MMENPCDialog') and
    TreeContains(targetVmad, 'Fragment_0') and
    not TreeContains(targetVmad, 'MME_Dialogues') and
    not TreeContains(targetVmad, 'Fragment_03');
end;

function Initialize: Integer;
var
  existingInfo, newInfo, vmad: IInterface;
  actualPrompt, actualResponse: string;
  createdInfo: Boolean;
begin
  Result := 1;
  createdInfo := False;
  TargetFile := FindFileByName(TargetPluginName);
  MMEFile := FindFileByName(MMEPluginName);
  SkyrimFile := FindFileByName(SkyrimPluginName);
  HearthFiresFile := FindFileByName(HearthFiresPluginName);

  if not Assigned(TargetFile) or not Assigned(MMEFile) or
     not Assigned(SkyrimFile) or not Assigned(HearthFiresFile) then begin
    AddMessage('ERROR: Load ' + SkyrimPluginName + ', ' +
      HearthFiresPluginName + ', ' + MMEPluginName + ' and ' +
      TargetPluginName + ' before running this script.');
    Exit;
  end;

  // A plugin may only depend on files that load before it. Catch this before
  // AddRequiredElementMasters raises an exception or any record is created.
  if GetLoadOrder(MMEFile) > GetLoadOrder(TargetFile) then begin
    AddMessage('ERROR: ' + MMEPluginName + ' currently loads after ' +
      TargetPluginName + '.');
    AddMessage('Move ' + TargetPluginName + ' after ' + MMEPluginName +
      ' in the load order, reload SSEEdit, and run this script again.');
    AddMessage('No records were created and neither plugin was modified.');
    Exit;
  end;

  existingInfo := FindRecordByEditorIDRecursive(TargetFile, 'INFO',
    NewInfoEditorID);
  SourceMatches := 0;
  SourceInfo := nil;
  FindSourceInfoRecursive(GroupBySignature(MMEFile, 'DIAL'));
  if SourceMatches <> 1 then begin
    AddMessage('ERROR: Expected exactly one MME INFO using ' +
      'MME_Dialogues.Fragment_03, found ' + IntToStr(SourceMatches) + '.');
    AddMessage('No records were created. This MME version must be inspected manually.');
    Exit;
  end;

  AddMessage('Validated MME source INFO: ' + Name(SourceInfo));
  if Assigned(existingInfo) then begin
    newInfo := existingInfo;
    AddMessage('Upgrading existing MME Extensions INFO: ' + Name(newInfo));
  end else begin
    AddRequiredElementMasters(SourceInfo, TargetFile, False);
    newInfo := wbCopyElementToFile(SourceInfo, TargetFile, True, True);
    if not Assigned(newInfo) then begin
      AddMessage('ERROR: xEdit could not copy the validated INFO as a new record.');
      Exit;
    end;
    createdInfo := True;
  end;

  SetEditorID(newInfo, NewInfoEditorID);
  SetElementEditValues(newInfo, 'RNAM', PlayerPrompt);

  if not ConfigureResponses(newInfo) then begin
    AddMessage('ERROR: The INFO responses could not be configured safely.');
    if createdInfo then
      Remove(newInfo);
    Exit;
  end;

  // Replace MME's native Lactacid action with our validation-only fragment.
  if not InstallTestFragment(newInfo, SourceInfo) then begin
    AddMessage('ERROR: MMENPCDialog test fragment could not be installed.');
    Exit;
  end;

  if not RebuildSupportedMilkConditions(newInfo, SourceInfo) then begin
    AddMessage('ERROR: Supported-milk dialogue conditions could not be installed.');
    Exit;
  end;

  actualPrompt := GetElementEditValues(newInfo, 'RNAM');
  actualResponse := GetElementEditValues(
    ElementByIndex(ElementByPath(newInfo, 'Responses'), 0), 'NAM1');

  if not SameText(actualPrompt, PlayerPrompt) or
     not SameText(actualResponse, NPCResponse) or
     (ElementCount(ElementByPath(newInfo, 'Responses')) <> 1) or
     not TreeContains(ElementBySignature(newInfo, 'VMAD'), 'MMENPCDialog') then begin
    AddMessage('ERROR: Post-write validation failed.');
    Exit;
  end;

  AddMessage('MME Extensions stage-one dialogue installed successfully.');
  AddMessage('New INFO: ' + Name(newInfo));
  AddMessage('Player prompt: ' + actualPrompt);
  AddMessage('NPC response: ' + actualResponse);
  AddMessage('Fragment: MMENPCDialog.Fragment_0');
  AddMessage('Any supported milk keeps the dialogue available; runtime selection preserves priority.');
  Result := 0;
end;

end.
