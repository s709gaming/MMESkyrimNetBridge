unit UserScript;

{
  Attaches the quest script required by Skyrim.Net's YAML PapyrusQuestAction.

  Required loaded file:
    MMEAlert.esp

  Safe to rerun: exits successfully if the script is already attached.
}

const
  TargetPluginName = 'MMEAlert.esp';
  TargetQuestEditorID = 'MMEAlertDebugQuest';
  TargetScriptName = 'MMESkyrimNetVoiceControls';

var
  TargetFile: IInterface;

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

function HasQuestScript(aQuest: IInterface; aScriptName: string): Boolean;
var
  scripts: IInterface;
  i: Integer;
begin
  Result := False;
  scripts := ElementByPath(aQuest, 'VMAD\Scripts');
  if not Assigned(scripts) then
    Exit;

  for i := 0 to ElementCount(scripts) - 1 do
    if SameText(GetElementEditValues(ElementByIndex(scripts, i), 'ScriptName'), aScriptName) then begin
      Result := True;
      Exit;
    end;
end;

function Initialize: Integer;
var
  targetQuest, vmad, scripts, scriptEntry: IInterface;
begin
  Result := 1;
  TargetFile := FindFileByName(TargetPluginName);
  if not Assigned(TargetFile) then begin
    AddMessage('ERROR: Load ' + TargetPluginName + ' before running this script.');
    Exit;
  end;

  targetQuest := MainRecordByEditorID(GroupBySignature(TargetFile, 'QUST'), TargetQuestEditorID);
  if not Assigned(targetQuest) then begin
    AddMessage('ERROR: Quest ' + TargetQuestEditorID + ' was not found in ' + TargetPluginName + '.');
    Exit;
  end;

  if HasQuestScript(targetQuest, TargetScriptName) then begin
    AddMessage(TargetScriptName + ' is already attached to ' + TargetQuestEditorID + '.');
    Result := 0;
    Exit;
  end;

  vmad := ElementBySignature(targetQuest, 'VMAD');
  if not Assigned(vmad) then begin
    Add(targetQuest, 'VMAD', True);
    vmad := ElementBySignature(targetQuest, 'VMAD');
  end;
  if not Assigned(vmad) then begin
    AddMessage('ERROR: Could not create VMAD data on ' + TargetQuestEditorID + '.');
    Exit;
  end;

  scripts := ElementByPath(vmad, 'Scripts');
  if not Assigned(scripts) then begin
    AddMessage('ERROR: Could not access the quest VMAD script list.');
    Exit;
  end;

  scriptEntry := ElementAssign(scripts, HighInteger, nil, False);
  SetElementEditValues(scriptEntry, 'ScriptName', TargetScriptName);
  if not HasQuestScript(targetQuest, TargetScriptName) then begin
    AddMessage('ERROR: Quest script attachment could not be verified.');
    Exit;
  end;

  AddMessage('Attached ' + TargetScriptName + ' to ' + TargetQuestEditorID + '.');
  Result := 0;
end;

end.