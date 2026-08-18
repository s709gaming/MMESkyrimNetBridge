unit UserScript;

{
  Rebuilds the malformed VMAD data on MMEAlertDebugQuest.

  The broken ESP splits MMEDrinkTracker across the alias and a quest script,
  so the player alias never receives OnObjectEquipped. This script preserves
  the existing PlayerAlias record and recreates only the VMAD script wiring.

  In SSEEdit, load MMEAlert.esp, right-click it, choose Apply Script, select
  this script, then save MMEAlert.esp.
}

const
  TargetPluginName = 'MMEAlert.esp';
  TargetQuestEditorID = 'MMEAlertDebugQuest';
  PlayerAliasID = 1;

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

function FindAliasByID(aAliases: IInterface; aAliasID: Integer): IInterface;
var
  i: Integer;
  aliasEntry: IInterface;
begin
  Result := nil;
  for i := 0 to ElementCount(aAliases) - 1 do begin
    aliasEntry := ElementByIndex(aAliases, i);
    if GetElementNativeValues(aliasEntry, 'ALST - Reference Alias ID') = aAliasID then begin
      Result := aliasEntry;
      Exit;
    end;
  end;
end;

procedure AddScript(aScripts: IInterface; aScriptName: string);
var
  scriptEntry: IInterface;
begin
  scriptEntry := ElementAssign(aScripts, HighInteger, nil, False);
  SetElementEditValues(scriptEntry, 'ScriptName', aScriptName);
end;

function Initialize: Integer;
var
  targetQuest: IInterface;
  aliases: IInterface;
  vmad: IInterface;
  scripts: IInterface;
  vmadAliases: IInterface;
  aliasVmad: IInterface;
begin
  Result := 1;
  TargetFile := FindFileByName(TargetPluginName);
  if not Assigned(TargetFile) then begin
    AddMessage('ERROR: Load ' + TargetPluginName + ' before running this script.');
    Exit;
  end;

  targetQuest := MainRecordByEditorID(GroupBySignature(TargetFile, 'QUST'), TargetQuestEditorID);
  if not Assigned(targetQuest) then begin
    AddMessage('ERROR: Quest ' + TargetQuestEditorID + ' was not found.');
    Exit;
  end;
  aliases := ElementByPath(targetQuest, 'Aliases');
  if not Assigned(aliases) or not Assigned(FindAliasByID(aliases, PlayerAliasID)) then begin
    AddMessage('ERROR: PlayerAlias ID 1 is missing. Run InstallMMEAlertPlayerAlias.pas first.');
    Exit;
  end;

  vmad := ElementBySignature(targetQuest, 'VMAD');
  if Assigned(vmad) then
    Remove(vmad);
  Add(targetQuest, 'VMAD', True);
  vmad := ElementBySignature(targetQuest, 'VMAD');
  scripts := ElementByPath(vmad, 'Scripts');
  AddScript(scripts, 'MMEDebug');
  AddScript(scripts, 'MMEAlertsMCM');
  AddScript(scripts, 'MMEAlertsController');
  AddScript(scripts, 'MMEAlertsQuickTest');
  AddScript(scripts, 'MMEAlertsFlatRateDefaults');
  AddScript(scripts, 'MMESkyrimNetVoiceControls');

  vmadAliases := ElementByPath(vmad, 'Aliases');
  aliasVmad := ElementAssign(vmadAliases, HighInteger, nil, False);
  SetElementEditValues(aliasVmad, 'Object Union\Object v2\FormID', Name(targetQuest));
  SetElementNativeValues(aliasVmad, 'Object Union\Object v2\Alias', PlayerAliasID);
  AddScript(ElementByPath(aliasVmad, 'Alias Scripts'), 'MMEDrinkTracker');

  AddMessage('Rebuilt MMEAlertDebugQuest VMAD.');
  AddMessage('Restored PlayerAlias ID 1 -> MMEDrinkTracker.');
  Result := 0;
end;

end.