unit UserScript;

var TargetFile, SkyrimNetFile: IInterface;

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

function TreeContains(e: IInterface; needle: string): Boolean;
var i: Integer;
begin
  Result := False;
  if Pos(needle, Name(e)) > 0 then begin Result := True; Exit; end;
  if Pos(needle, GetEditValue(e)) > 0 then begin Result := True; Exit; end;
  for i := 0 to ElementCount(e) - 1 do
    if TreeContains(ElementByIndex(e, i), needle) then begin
      Result := True;
      Exit;
    end;
end;

function FindQuestWithAliasScript(aFile: IInterface; scriptName: string): IInterface;
var group, q, vmad: IInterface; i: Integer;
begin
  Result := nil;
  group := GroupBySignature(aFile, 'QUST');
  for i := 0 to ElementCount(group) - 1 do begin
    q := ElementByIndex(group, i);
    vmad := ElementBySignature(q, 'VMAD');
    if Assigned(vmad) and TreeContains(vmad, scriptName) then begin
      Result := q;
      Exit;
    end;
  end;
end;

function Initialize: Integer;
var targetQuest, sourceQuest, sourceAliases, sourceAlias, targetAliases,
    sourceVmadAliases, sourceVmadAlias, targetVmadAliases, newAlias,
    newVmadAlias, scripts, scriptEntry: IInterface;
begin
  Result := 1;
  TargetFile := FindFileByName('MMEAlert.esp');
  SkyrimNetFile := FindFileByName('SkyrimNet.esp');
  if not Assigned(TargetFile) or not Assigned(SkyrimNetFile) then begin
    AddMessage('ERROR: Load MMEAlert.esp and SkyrimNet.esp.');
    Exit;
  end;

  targetQuest := MainRecordByEditorID(GroupBySignature(TargetFile, 'QUST'), 'MMEAlertDebugQuest');
  sourceQuest := FindQuestWithAliasScript(SkyrimNetFile, 'skynet_PlayerAlias');
  if not Assigned(targetQuest) or not Assigned(sourceQuest) then begin
    AddMessage('ERROR: Target quest or SkyrimNet player-alias quest was not found.');
    Exit;
  end;

  targetAliases := ElementByPath(targetQuest, 'Aliases');
  targetVmadAliases := ElementByPath(targetQuest, 'VMAD\Aliases');
  if (Assigned(targetAliases) and (ElementCount(targetAliases) > 0)) or
     (Assigned(targetVmadAliases) and (ElementCount(targetVmadAliases) > 0)) then begin
    AddMessage('ERROR: MMEAlertDebugQuest already has alias data. No changes made.');
    Exit;
  end;

  sourceAliases := ElementByPath(sourceQuest, 'Aliases');
  sourceVmadAliases := ElementByPath(sourceQuest, 'VMAD\Aliases');
  if not Assigned(sourceAliases) or (ElementCount(sourceAliases) = 0) or
     not Assigned(sourceVmadAliases) or (ElementCount(sourceVmadAliases) = 0) then begin
    AddMessage('ERROR: SkyrimNet player alias structure could not be read.');
    Exit;
  end;

  if not Assigned(targetAliases) then targetAliases := Add(targetQuest, 'Aliases', True);
  if not Assigned(targetVmadAliases) then targetVmadAliases := Add(ElementBySignature(targetQuest, 'VMAD'), 'Aliases', True);

  sourceAlias := ElementByIndex(sourceAliases, 0);
  newAlias := ElementAssign(targetAliases, HighInteger, sourceAlias, False);
  SetElementNativeValues(newAlias, 'ALST - Reference Alias ID', 1);
  SetElementEditValues(newAlias, 'ALID - Alias Name', 'PlayerAlias');
  SetElementNativeValues(targetQuest, 'ANAM - Next Alias ID', 2);

  // Build the VMAD alias locally. Copying SkyrimNet's VMAD entry would also try
  // to copy its quest link and script properties, causing an unwanted master.
  newVmadAlias := ElementAssign(targetVmadAliases, HighInteger, nil, False);
  SetElementEditValues(newVmadAlias, 'Object Union\Object v2\FormID', Name(targetQuest));
  SetElementNativeValues(newVmadAlias, 'Object Union\Object v2\Alias', 1);
  scripts := ElementByPath(newVmadAlias, 'Alias Scripts');
  scriptEntry := ElementAssign(scripts, HighInteger, nil, False);
  SetElementEditValues(scriptEntry, 'ScriptName', 'MMEDrinkTracker');

  AddMessage('MME Alerts player alias installed.');
  AddMessage('Alias: ' + GetElementEditValues(newAlias, 'ALST - Reference Alias ID') + ' ' +
    GetElementEditValues(newAlias, 'ALID - Alias Name'));
  AddMessage('Unique actor: ' + GetElementEditValues(newAlias, 'ALUA - Unique Actor'));
  AddMessage('Alias quest: ' + GetElementEditValues(newVmadAlias, 'Object Union\Object v2\FormID'));
  AddMessage('Alias script: ' + GetElementEditValues(scriptEntry, 'ScriptName'));
  Result := 0;
end;

end.
