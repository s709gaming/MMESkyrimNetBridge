unit UserScript;

{
  Removes only the unwanted copied final response from the MME Extensions
  milk-giving INFO. Safe to rerun; refuses ambiguous records or responses.

  Required loaded file:
    MMEAlert.esp
}

const
  TargetPluginName = 'MMEAlert.esp';
  TargetEditorID = 'MMEExt_DialogueDrinkMilk';
  WantedResponse = 'Yes! I can''t wait to be nice and heavy!';
  UnwantedResponse = 'I hope you will give me some good milking soon!';

var
  TargetFile, TargetInfo: IInterface;
  TargetMatches: Integer;

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

procedure FindTargetInfoRecursive(aElement: IInterface);
var
  i: Integer;
begin
  if not Assigned(aElement) then
    Exit;

  if (Signature(aElement) = 'INFO') and
     SameText(EditorID(aElement), TargetEditorID) then begin
    Inc(TargetMatches);
    TargetInfo := aElement;
  end;

  for i := 0 to ElementCount(aElement) - 1 do
    FindTargetInfoRecursive(ElementByIndex(aElement, i));
end;

function Initialize: Integer;
var
  responses, response: IInterface;
  i, responseCount, wantedCount, unwantedCount, unwantedIndex: Integer;
  responseText: string;
begin
  Result := 1;
  TargetFile := FindFileByName(TargetPluginName);
  if not Assigned(TargetFile) then begin
    AddMessage('ERROR: Load ' + TargetPluginName + ' before running this script.');
    Exit;
  end;

  TargetInfo := nil;
  TargetMatches := 0;
  FindTargetInfoRecursive(GroupBySignature(TargetFile, 'DIAL'));
  if TargetMatches <> 1 then begin
    AddMessage('ERROR: Expected exactly one INFO with EditorID ' +
      TargetEditorID + ', found ' + IntToStr(TargetMatches) + '.');
    AddMessage('No records were modified.');
    Exit;
  end;

  AddMessage('Found target INFO: ' + Name(TargetInfo));
  responses := ElementByPath(TargetInfo, 'Responses');
  if not Assigned(responses) then begin
    AddMessage('ERROR: Target INFO has no Responses element. No records were modified.');
    Exit;
  end;

  responseCount := ElementCount(responses);
  wantedCount := 0;
  unwantedCount := 0;
  unwantedIndex := -1;
  AddMessage('Found ' + IntToStr(responseCount) + ' response(s):');
  for i := 0 to responseCount - 1 do begin
    response := ElementByIndex(responses, i);
    responseText := GetElementEditValues(response, 'NAM1');
    AddMessage('  Response ' + IntToStr(i) + ': ' + responseText);
    if SameText(responseText, WantedResponse) then
      Inc(wantedCount)
    else if SameText(responseText, UnwantedResponse) then begin
      Inc(unwantedCount);
      unwantedIndex := i;
    end;
  end;

  if (responseCount = 1) and (wantedCount = 1) and
     (unwantedCount = 0) then begin
    AddMessage('Already repaired: only the wanted response remains.');
    Result := 0;
    Exit;
  end;

  if (responseCount <> 2) or (wantedCount <> 1) or
     (unwantedCount <> 1) then begin
    AddMessage('ERROR: Responses do not match the exact expected pair.');
    AddMessage('No records were modified.');
    Exit;
  end;

  Remove(ElementByIndex(responses, unwantedIndex));
  if (ElementCount(responses) <> 1) or
     not SameText(GetElementEditValues(ElementByIndex(responses, 0), 'NAM1'),
       WantedResponse) then begin
    AddMessage('ERROR: Post-removal validation failed; inspect the INFO before saving.');
    Exit;
  end;

  AddMessage('Removed only: ' + UnwantedResponse);
  AddMessage('Kept: ' + WantedResponse);
  AddMessage('Repair completed successfully. Save ' + TargetPluginName + '.');
  Result := 0;
end;

end.
