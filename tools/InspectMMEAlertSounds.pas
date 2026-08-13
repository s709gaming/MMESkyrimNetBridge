unit UserScript;

function Initialize: Integer;
var
  i, j: Integer;
  f, g, r: IInterface;
begin
  Result := 0;
  for i := 0 to FileCount - 1 do begin
    f := FileByIndex(i);
    if SameText(GetFileName(f), 'MMEAlert.esp') then begin
      AddMessage('FOUND FILE: ' + GetFileName(f));
      g := GroupBySignature(f, 'SNDR');
      if not Assigned(g) then begin
        AddMessage('NO SNDR GROUP');
        Exit;
      end;
      AddMessage('SNDR COUNT: ' + IntToStr(ElementCount(g)));
      for j := 0 to ElementCount(g) - 1 do begin
        r := ElementByIndex(g, j);
        AddMessage('SNDR: ' + Name(r));
        AddMessage('  FORMID: ' + IntToHex(GetLoadOrderFormID(r), 8));
        AddMessage('  LOCAL: ' + IntToHex(GetLoadOrderFormID(r) and $00FFFFFF, 6));
        AddMessage('  PATH: ' + GetElementEditValues(r, 'ANAM'));
        AddMessage('  ELEMENTS: ' + Path(r));
      end;
      Exit;
    end;
  end;
  AddMessage('MMEAlert.esp NOT LOADED');
end;

end.
