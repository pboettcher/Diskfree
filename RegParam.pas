unit RegParam;

interface

uses Windows;

function GetRegInteger(Param:string; Default:integer):integer;
function GetRegString(Param:string):string;
procedure SetRegInteger(Param:string; Value:integer);
procedure SetRegString(Param,Value:string);

implementation

uses Registry;

const RegKeyName='Software\BoettcherPKSoft\DiskFree32';

function GetRegInteger(Param:string; Default:integer):integer;
var Reg:TRegistry;
begin
  Reg:=TRegistry.Create;
  Result:=Default;
  if Reg.OpenKey(RegKeyName,True) then begin
    if not Reg.ValueExists(Param) then begin
      {Если параметр не существует, создаём его}
      Reg.WriteInteger(Param,Default);
      Result:=Default;
    end
    else Result:=Reg.ReadInteger(Param);
    Reg.CloseKey;
  end;
  Reg.Destroy;
end;

function GetRegString(Param:string):string;
var Reg:TRegistry;
begin
  Reg:=TRegistry.Create;
  Result:='';
  if Reg.OpenKey(RegKeyName,True) then begin
    if Reg.ValueExists(Param) then Result:=Reg.ReadString(Param);
    Reg.CloseKey;
  end;
  Reg.Destroy;
end;

procedure SetRegInteger(Param:string; Value:integer);
var Reg:TRegistry;
begin
  Reg:=TRegistry.Create;
  if Reg.OpenKey(RegKeyName,True) then begin
    Reg.WriteInteger(Param,Value);
    Reg.CloseKey;
  end;
  Reg.Destroy;
end;

procedure SetRegString(Param,Value:string);
var Reg:TRegistry;
begin
  Reg:=TRegistry.Create;
  if Reg.OpenKey(RegKeyName,True) then begin
    Reg.WriteString(Param,Value);
    Reg.CloseKey;
  end;
  Reg.Destroy;
end;

end.

