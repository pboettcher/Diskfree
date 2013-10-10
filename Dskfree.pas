unit Dskfree;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms,
  TntForms, Dialogs, Grids, ExtCtrls, TntMenus, Tray, Menus, StdCtrls,
  TntStdCtrls, TntGrids;

type
  TOSVersion = (ovUnknown, ovWin32s, ovWin95Retail, ovWindows, ovNT);

  TForm1 = class(TTntForm)
    Grid: TTntStringGrid;
    Timer1: TTimer;
    PopupMenu1: TTntPopupMenu;
    miShow: TTntMenuItem;
    miHide: TTntMenuItem;
    miSeparator1: TTntMenuItem;
    miExit: TTntMenuItem;
    miSettings: TTntMenuItem;
    miSeparator2: TTntMenuItem;
    HideBtn: TTntButton;
    procedure FormShow(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure Timer1Timer(Sender: TObject);
    procedure miShowClick(Sender: TObject);
    procedure miHideClick(Sender: TObject);
    procedure miExitClick(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure miSettingsClick(Sender: TObject);
    procedure GridMouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    procedure GridMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure GridMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure HideBtnClick(Sender: TObject);
  private
    FLock:Boolean;
    FLockXPos, FLockYPos:Integer;
    FFormXPos, FFormYPos:Integer;
    FOSVer:TOSVersion;
    procedure RestoreForm;
    procedure HideForm;
    procedure RestorePosition;
    procedure SavePosition;
    procedure SetRefresh(RefInt:byte);
    procedure Terminate;
    procedure MouseDownHandler;
    procedure MouseMoveHandler;
    procedure MouseUpHandler;
    function SPercent(Free, Total: Int64): Currency;
    procedure ShowFreeSpace;
    function GetOSVer: TOSVersion;
    procedure FixedFreeSpace(RootPath: string; var FreeAvailable,
      TotalSpace: Int64);
    procedure ErrMsg(Msg: String);
    procedure ShowErrorAndTerminate(Msg: String);
  public
    constructor Create(AOwner:TComponent); override;
    destructor Destroy; override;
    procedure WMICON(var msg:TMessage); message WM_MYICONNOTIFY;
    procedure WMSYSCOMMAND(var msg:TMessage);message WM_SYSCOMMAND;
    procedure WMENDSESSION(var msg:TMessage);message WM_ENDSESSION;
  end;

var
  Form1:TForm1;

implementation

{$R *.DFM}

uses ShellAPI, RegParam, Params, Autorun;

var RefInt:byte;

{Узнать версию ОС}
function TForm1.GetOSVer:TOSVersion;
var VerInfo:_OSVersionInfoA;
begin
  VerInfo.dwOSVersionInfoSize:=SizeOf(_OSVersionInfoA);
  GetVersionEx(VerInfo);
  if VerInfo.dwPlatformId=VER_PLATFORM_WIN32s then Result:=ovWin32s
  else begin //Если не Win32s
    if (VerInfo.dwPlatformId=VER_PLATFORM_WIN32_WINDOWS)and
       (VerInfo.dwMajorVersion=4)and
       (VerInfo.dwMinorVersion=0)and
       (VerInfo.dwBuildNumber=67109814)
    then
      Result:=ovWin95Retail
    else
      case VerInfo.dwPlatformId of
        VER_PLATFORM_WIN32_WINDOWS: Result:=ovWindows;
        VER_PLATFORM_WIN32_NT: Result:=ovNT;
      else
        Result:=ovUnknown;
      end;
    {67109814=40003B6h
     400 - Версия (4.00)
     03B6=950 - Build}
  end;
end;

procedure TForm1.FixedFreeSpace(RootPath:string; var FreeAvailable, TotalSpace:Int64);
var
  lpRPName:array[0..256]of Char; //Root Path Name
  lpSPC:cardinal;  //Sectors Per Cluster
  lpBPS:cardinal;  //Bytes Per Sector
  lpFCN:cardinal;  //Number Of Free Clusters
  lpTCN:cardinal; //Total Number Of Clusters
begin
  FreeAvailable:=-1;
  TotalSpace:=-1;
  StrPCopy(lpRPName,RootPath);
  if GetDriveType(lpRPName)=Drive_Fixed then begin
    if FOSVer=ovWin95Retail then begin
      if GetDiskFreeSpace(lpRPName, lpSPC, lpBPS, lpFCN,
        lpTCN) then begin
        FreeAvailable:=lpFCN*lpSPC*lpBPS;
        TotalSpace:=-1;
      end;
    end
    else begin
      if not GetDiskFreeSpaceEx(lpRPName,FreeAvailable,
        TotalSpace, nil) then begin
          FreeAvailable:=-1;
          TotalSpace:=-1;
        end;
    end;
  end;
end;

function SepNumStr(Num:Int64):string;
var flt:double;
begin
  flt:=Num;
  Result:=Format('%.0n',[flt]);
end;

procedure TForm1.FormShow(Sender: TObject);
begin
  Application.Title:='Свободное место на несменных дисках';
  SysUtils.ThousandSeparator:=',';
  with Grid do begin
    FixedRows:=0;
    ColWidths[0]:=20;
    ColWidths[1]:=100;
    ColWidths[2]:=40;
    Self.ShowFreeSpace;
    Self.Width:=158;
    HideBtn.Left:=Grid.Width-HideBtn.Width;
    HideBtn.Top:=0;
  end;
  RestorePosition;
end;

procedure TForm1.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if (Key=27)or(Key=13)then Close;
end;

function TForm1.SPercent(Free, Total:Int64):Currency;
var PerCent:Currency;
begin
  PerCent:=Trunc((Free/Total)*1000)*0.1;
  if PerCent<10 then Result:=PerCent
    else Result:=Trunc(PerCent);
end;

procedure TForm1.ShowFreeSpace;
var i:integer;
    FS, TS:Int64;
    Drives:LongWord;
    Letter:String;
    Cnt:Integer;
    Available:Boolean;
begin
  if not Self.Visible then Exit;
  Timer1.Enabled:=False;
  Drives:=GetLogicalDrives;
  Cnt:=0;
  for i:=0 to 25 do begin
    Available := (Drives and 1) > 0;
    Drives := Drives shr 1;
    if not Available then Continue;
    Letter:=Char(65+i)+':';
    FixedFreeSpace(Letter+'\', FS, TS);
    if FS>=0 then begin
      if Grid.RowCount<Cnt+1 then Grid.RowCount:=Cnt+1;
      Grid.Cells[0,Cnt]:=Letter;
      Grid.Cells[1,Cnt]:=SepNumStr(FS);
      Grid.Cells[2,Cnt]:=CurrToStr(SPercent(FS, TS))+'%';
      Inc(Cnt);
    end;
  end;
  Grid.RowCount:=Cnt;
  Self.Height:=Grid.DefaultRowHeight*Grid.RowCount+BorderWidth*2+3;
  Timer1.Enabled:=True;
end;

procedure TForm1.Timer1Timer(Sender: TObject);
begin
  ShowFreeSpace;
end;

procedure TForm1.ErrMsg(Msg:String);
begin
  MessageBox(Handle, PChar(Msg), 'Error', MB_ICONERROR);
end;

procedure TForm1.ShowErrorAndTerminate(Msg:String);
begin
  ErrMsg(Msg);
  if CallTerminateProcs then PostQuitMessage(0);
end;

constructor TForm1.Create(AOwner:TComponent);
begin
  inherited Create(AOwner);
  CreateTrayIcon(Handle, Application.Icon.Handle, 0);
  FOSVer:=GetOSVer;
  if FOSVer=ovWin32s then
    ShowErrorAndTerminate('This software cannot run under Win32s subsystem.');
  if FOSVer=ovWin32s then
    ShowErrorAndTerminate('Could not determine OS version.');
  RefInt:=GetRegInteger('RefreshInterval',1);
  SetRefresh(RefInt);
end;

destructor TForm1.Destroy;
begin
  DeleteTrayIcon(Handle,0);
  SavePosition;
  inherited Destroy;
end;

procedure TForm1.WMICON(var msg:TMessage);
var P:TPoint;
begin
  case msg.LParam of
    WM_RBUTTONUP:
      begin
        GetCursorPos(P);
        SetForegroundWindow(Application.MainForm.Handle);
        PopupMenu1.Popup(P.X,P.Y);
      end;
    WM_LBUTTONDOWN: if Self.Visible then HideForm else RestoreForm;
  end;
end;

procedure TForm1.WMSYSCOMMAND(var msg:TMessage);
begin
  inherited;
  if Msg.wParam=SC_MINIMIZE then HideForm;
end;

procedure TForm1.miShowClick(Sender: TObject);
begin
  RestoreForm;
end;

procedure TForm1.miHideClick(Sender: TObject);
begin
  HideForm;
end;

procedure TForm1.miExitClick(Sender: TObject);
begin
  Terminate;
end;

procedure TForm1.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  if Visible then begin
    HideForm;
    CanClose:=False; //Только если форма видима, иначе
                     //не завершить работу Windows
  end
  else CanClose:=True;
end;

procedure TForm1.RestoreForm;
begin
  Self.Show;
  HideBtn.Visible:=False;
  miShow.Enabled:=False;
  miHide.Enabled:=True;
end;

procedure TForm1.HideForm;
begin
  SavePosition;
  HideBtn.Visible:=False;
  Self.Hide;
  miShow.Enabled:=True;
  miHide.Enabled:=False;
end;

procedure TForm1.SavePosition;
begin
  SetRegInteger('PosX',Left);
  SetRegInteger('PosY',Top);
end;

procedure TForm1.RestorePosition;
begin
  Left:=GetRegInteger('PosX',Screen.Width-Width);
  Top:=GetRegInteger('PosY',10);
end;

procedure TForm1.miSettingsClick(Sender: TObject);
const ProgName='DiskFreeMonitor';
var ARun,ExARun,Admin,LocalAr,GlobalAr:boolean;
    ChangeGlobalAr:boolean;
    ExRefInt:byte;
    ProgPath:string;
begin
  Admin:=False;
  ProgPath:=ParamStr(0);
  LocalAr:=QueryLocalAutorun(ProgName,ProgPath);
  GlobalAr:=QueryGlobalAutorun(ProgName,ProgPath);
  ARun:=LocalAr or GlobalAr;
  {интервал обновления}
  if RefInt=0 then RefInt:=1;
  {смена параметров}
  ExRefInt:=RefInt;
  ExARun:=ARun;
  ChangeParams(RefInt,ARun,GlobalAr and(not Admin));
  {интервал обновления}
  if RefInt<>ExRefInt then begin
    if RefInt=0 then RefInt:=1;
    SetRefresh(RefInt);
    SetRegInteger('RefreshInterval',RefInt);
  end;
  {автозапуск}
  if ARun=ExARun then Exit;
  ChangeGlobalAr:=False;
  if Admin then
    if MessageDlg('Изменить параметры автозапуска для '+
    'всех пользователей?',mtConfirmation,[mbYes,mbNo],
    0)=mrYes then ChangeGlobalAr:=True;
  if ARun then begin
    {Устанавливаем автозапуск}
    if ChangeGlobalAr then begin
      SetGlobalAutorun(ProgName,ProgPath);
      DeleteLocalAutorun(ProgName);
    end
    else if not GlobalAr then SetLocalAutorun(ProgName,ProgPath);
  end
  else begin
    {Удаляем автозапуск}
    DeleteLocalAutorun(ProgName);
    if ChangeGlobalAr then DeleteGlobalAutorun(ProgName);
  end;
end;

procedure TForm1.SetRefresh(RefInt:byte);
begin
  Timer1.Interval:=RefInt*1000;
end;

procedure TForm1.WMENDSESSION(var msg: TMessage);
begin
  Terminate;
end;

procedure TForm1.Terminate;
begin
  if CallTerminateProcs then PostQuitMessage(0);
end;

procedure TForm1.MouseMoveHandler;
var CurPoint:TPoint;
    DifX, DifY:Integer;
begin
  if FLock then Screen.Cursor:=crSizeAll
  else begin
    Screen.Cursor:=crDefault;
    GetCursorPos(CurPoint);
    CurPoint:=Grid.ScreenToClient(CurPoint);
    DifX:=Grid.Width-CurPoint.X;
    DifY:=CurPoint.Y;
    if (DifX < HideBtn.Width) and (DifX > 0) and
      (DifY > 0)and(DifY < HideBtn.Height) then
        HideBtn.Visible:=True
        else
        HideBtn.Visible:=False;
    Exit;
  end;
  GetCursorPos(CurPoint);
  Left := FFormXPos + CurPoint.X - FLockXPos;
  Top := FFormYPos + CurPoint.Y - FLockYPos;
end;

procedure TForm1.MouseDownHandler;
var CurPoint:TPoint;
begin
  if ((GetKeyState(VK_LBUTTON) and $80) = 0) then Exit; //Left button
  FLock:=True;
  GetCursorPos(CurPoint);
  FLockXPos := CurPoint.X;
  FLockYPos := CurPoint.Y;
  FFormXPos := Self.Left;
  FFormYPos := Self.Top;
  Screen.Cursor:=crSizeAll;
end;

procedure TForm1.MouseUpHandler;
begin
  FLock:=False;
  Screen.Cursor:=crDefault;
end;

procedure TForm1.GridMouseMove(Sender: TObject; Shift: TShiftState; X,
  Y: Integer);
begin
  MouseMoveHandler;
end;

procedure TForm1.GridMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  MouseDownHandler;
end;

procedure TForm1.GridMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  MouseUpHandler;
end;

procedure TForm1.HideBtnClick(Sender: TObject);
begin
  HideForm;
end;

end.

