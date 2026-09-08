unit UserScript;

{
  Removes the invalid MMEDiagnostics attachment from MMEAlertDebugQuest.

  MMEDiagnostics is a Hidden global utility script and does not extend Quest,
  so attaching it to a QUST record produces a Papyrus base-type mismatch.
  This repair preserves every other quest script, property, and alias.

  In SSEEdit, load MMEAlert.esp, right-click it, choose Apply Script, select
  this script, then save MMEAlert.esp.
}

const
  TargetPluginName = 'MMEAlert.esp';
  TargetQuestEditorID = 'MMEAlertDebugQuest';
  InvalidScriptName = 'MMEDiagnostics';

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

function Initialize: Integer;
var
  targetFile: IInterface;
  targetQuest: IInterface;
  scripts: IInterface;
  scriptEntry: IInterface;
  i: Integer;
  removedCount: Integer;
begin
  Result := 1;
  targetFile := FindFileByName(TargetPluginName);
  if not Assigned(targetFile) then begin
    AddMessage('ERROR: Load ' + TargetPluginName + ' before running this script.');
    Exit;
  end;

  targetQuest := MainRecordByEditorID(GroupBySignature(targetFile, 'QUST'), TargetQuestEditorID);
  if not Assigned(targetQuest) then begin
    AddMessage('ERROR: Quest ' + TargetQuestEditorID + ' was not found.');
    Exit;
  end;

  scripts := ElementByPath(targetQuest, 'VMAD\Scripts');
  if not Assigned(scripts) then begin
    AddMessage('No quest scripts found; nothing to repair.');
    Result := 0;
    Exit;
  end;

  removedCount := 0;
  for i := ElementCount(scripts) - 1 downto 0 do begin
    scriptEntry := ElementByIndex(scripts, i);
    if SameText(GetElementEditValues(scriptEntry, 'ScriptName'), InvalidScriptName) then begin
      Remove(scriptEntry);
      Inc(removedCount);
    end;
  end;

  if removedCount = 0 then
    AddMessage('MMEDiagnostics was not attached; nothing changed.')
  else
    AddMessage('Removed invalid MMEDiagnostics quest attachment(s): ' + IntToStr(removedCount));

  AddMessage('All other MMEAlertDebugQuest VMAD scripts and aliases were preserved.');
  Result := 0;
end;

end.
