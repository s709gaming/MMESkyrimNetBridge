unit UserScript;

var SkyrimNetFile: IInterface;

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

procedure DumpTree(e: IInterface; depth: Integer);
var i: Integer; child: IInterface; pad, value: string;
begin
  if depth > 6 then Exit;
  pad := StringOfChar(' ', depth * 2);
  value := GetEditValue(e);
  if Length(value) > 120 then value := Copy(value, 1, 120) + '...';
  AddMessage(pad + Name(e) + ' | path=' + Path(e) + ' | value=' + value);
  for i := 0 to ElementCount(e) - 1 do begin
    child := ElementByIndex(e, i);
    DumpTree(child, depth + 1);
  end;
end;

function TreeContains(e: IInterface; needle: string): Boolean;
var i: Integer; child: IInterface;
begin
  Result := False;
  if Pos(needle, Name(e)) > 0 then begin
    Result := True;
    Exit;
  end;
  if Pos(needle, GetEditValue(e)) > 0 then begin
    Result := True;
    Exit;
  end;
  for i := 0 to ElementCount(e) - 1 do begin
    child := ElementByIndex(e, i);
    if TreeContains(child, needle) then begin
      Result := True;
      Exit;
    end;
  end;
end;

function Initialize: Integer;
var group, q, vmad: IInterface; i: Integer;
begin
  Result := 1;
  SkyrimNetFile := FindFileByName('SkyrimNet.esp');
  if not Assigned(SkyrimNetFile) then begin
    AddMessage('ERROR: Load SkyrimNet.esp.');
    Exit;
  end;
  group := GroupBySignature(SkyrimNetFile, 'QUST');
  for i := 0 to ElementCount(group) - 1 do begin
    q := ElementByIndex(group, i);
    vmad := ElementBySignature(q, 'VMAD');
    if Assigned(vmad) then begin
      if TreeContains(vmad, 'skynet_PlayerAlias') then begin
        AddMessage('FOUND QUEST: ' + Name(q));
        DumpTree(q, 0);
        Result := 0;
        Exit;
      end;
    end;
  end;
  AddMessage('ERROR: No SkyrimNet quest containing skynet_PlayerAlias was found.');
end;

end.
