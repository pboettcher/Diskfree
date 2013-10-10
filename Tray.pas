unit Tray;

interface

uses Windows, ShellAPI, Messages, SysUtils;

const
  WM_MYICONNOTIFY=WM_USER+123;

procedure CreateTrayIcon(Handle:HWND; IHandle:HWND;
  n:Integer);
procedure DeleteTrayIcon(Handle:HWND; n:Integer);

implementation

procedure CreateTrayIcon(Handle:HWND; IHandle:HWND;
  n:Integer);
var NIData:TNotifyIconData;
begin
  with NIData do begin
    cbSize:=SizeOf(TNotifyIconData);
    {HWND ������ ���� (����, ������������ ��������
     ���������)}
    Wnd:=Handle;
    uID:=n; //����� ������
    uFlags:=NIF_ICON or NIF_MESSAGE or NIF_TIP;
    uCallBackMessage:=WM_MYICONNOTIFY; //�������� ���������
    {��, ������ ����������� ������ ��� ����� ���� �
     ImageList � �.�.}
    hIcon:=IHandle;
    StrPCopy(szTip,'��������� ����� �� ��������� ������'); //����������� ������
  end;
  Shell_NotifyIcon(NIM_ADD,@NIData); //���������� ������
end;

procedure DeleteTrayIcon(Handle:HWND; n:Integer);
var NIData:TNotifyIconData;
begin
  with NIData do begin
    cbSize:=SizeOf(TNotifyIconData);
    Wnd:=Handle;
    uID:=n;
  end;
  Shell_NotifyIcon(NIM_DELETE,@NIData); //�������� ������
end;

end.

