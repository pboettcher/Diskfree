unit Params;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls;

type
  TfrmParams = class(TForm)
    lblRefresh: TLabel;
    edRefresh: TEdit;
    btnOk: TButton;
    Button1: TButton;
    cbAutorun: TCheckBox;
  private
    procedure SetAutoRun(const Value: boolean);
    procedure SetAutorunLock(const Value: boolean);
    procedure SetInterval(const Value: byte);
    function GetAutoRun: boolean;
    function GetInterval: byte;
    function GetAutorunLock: boolean;
  public
    property Interval:byte read GetInterval write SetInterval;
    property AutoRun:boolean read GetAutoRun write SetAutoRun;
    property AutorunLock:boolean read GetAutorunLock write SetAutorunLock;
  end;

procedure ChangeParams(var Interval:byte;
  var AutoRun:boolean; AutorunLock:boolean);

implementation

{$R *.dfm}

procedure ChangeParams(var Interval:byte;
  var AutoRun:boolean; AutorunLock:boolean);
var Frm:TfrmParams;
    CP:TPoint;
begin
  Frm := TfrmParams.Create(nil);
  try
    GetCursorPos(CP);
    if CP.X+Frm.Width>Screen.WorkAreaRect.Right then CP.X:=Screen.WorkAreaRect.Right-Frm.Width;
    if CP.Y+Frm.Height>Screen.WorkAreaRect.Bottom then CP.Y:=Screen.WorkAreaRect.Bottom-Frm.Height;
    Frm.Left := CP.X;
    Frm.Top := CP.Y;
    Frm.Interval := Interval;
    Frm.AutoRun := AutoRun;
    Frm.AutorunLock := AutorunLock;
    if Frm.ShowModal=mrOk then begin
      Interval := Frm.Interval;
      if not AutorunLock then AutoRun := Frm.AutoRun;
    end;
  finally
    Frm.Release;
  end;
end;

{ TfrmParams }

function TfrmParams.GetAutoRun: boolean;
begin
  Result:=cbAutorun.Checked;
end;

function TfrmParams.GetAutorunLock: boolean;
begin
  Result:=not cbAutorun.Enabled;
end;

function TfrmParams.GetInterval: byte;
begin
  Result:=StrToInt(edRefresh.Text);
end;

procedure TfrmParams.SetAutoRun(const Value: boolean);
begin
  cbAutorun.Checked:=Value;
end;

procedure TfrmParams.SetAutorunLock(const Value: boolean);
begin
  cbAutorun.Enabled:=not AutorunLock;
end;

procedure TfrmParams.SetInterval(const Value: byte);
begin
  edRefresh.Text:=IntToStr(Interval);
end;

end.

