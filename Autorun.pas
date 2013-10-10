unit Autorun;

interface

uses Windows,Registry;

function QueryLocalAutorun(Name,Path:string):boolean;
function QueryGlobalAutorun(Name,Path:string):boolean;
procedure SetLocalAutorun(Name,Path:string);
procedure SetGlobalAutorun(Name,Path:string);
procedure DeleteLocalAutorun(Name:string);
procedure DeleteGlobalAutorun(Name:string);

implementation

const
  ArKey='Software\Microsoft\Windows\CurrentVersion\Run';

function QueryLocalAutorun(Name,Path:string):boolean;
var Reg:TRegistry;
begin
  Result:=False;
  Reg:=TRegistry.Create;
  if Reg.OpenKey(ArKey,False) then begin
    if Reg.ValueExists(Name) then
      if Reg.ReadString(Name)=Path then Result:=True;
    Reg.CloseKey;
  end;
  Reg.Destroy;
end;

function QueryGlobalAutorun(Name,Path:string):boolean;
var Reg:TRegistry;
begin
  Result:=False;
  Reg:=TRegistry.Create;
  Reg.RootKey:=HKEY_LOCAL_MACHINE;
  if Reg.OpenKey(ArKey,False) then begin
    if Reg.ValueExists(Name) then
      if Reg.ReadString(Name)=Path then Result:=True;
    Reg.CloseKey;
  end;
  Reg.Destroy;
end;

procedure SetLocalAutorun(Name,Path:string);
var Reg:TRegistry;
begin
  Reg:=TRegistry.Create;
  if Reg.OpenKey(ArKey,True) then begin
    Reg.WriteString(Name,Path);
    Reg.CloseKey;
  end;
  Reg.Destroy;
end;

procedure SetGlobalAutorun(Name,Path:string);
var Reg:TRegistry;
begin
  Reg:=TRegistry.Create;
  Reg.RootKey:=HKEY_LOCAL_MACHINE;
  if Reg.OpenKey(ArKey,True) then begin
    Reg.WriteString(Name,Path);
    Reg.CloseKey;
  end;
  Reg.Destroy;
end;

procedure DeleteLocalAutorun(Name:string);
var Reg:TRegistry;
begin
  Reg:=TRegistry.Create;
  if Reg.OpenKey(ArKey,False) then begin
    if Reg.ValueExists(Name) then Reg.DeleteValue(Name);
    Reg.CloseKey;
  end;
  Reg.Destroy;
end;

procedure DeleteGlobalAutorun(Name:string);
var Reg:TRegistry;
begin
  Reg:=TRegistry.Create;
  Reg.RootKey:=HKEY_LOCAL_MACHINE;
  if Reg.OpenKey(ArKey,False) then begin
    if Reg.ValueExists(Name) then Reg.DeleteValue(Name);
    Reg.CloseKey;
  end;
  Reg.Destroy;
end;

end.

