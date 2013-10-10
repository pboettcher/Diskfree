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
    {HWND нашего окна (окна, принимающего обратные
     сообщения)}
    Wnd:=Handle;
    uID:=n; //номер значка
    uFlags:=NIF_ICON or NIF_MESSAGE or NIF_TIP;
    uCallBackMessage:=WM_MYICONNOTIFY; //обратное сообщение
    {то, откуда сдёргивается значок это может быть и
     ImageList и т.д.}
    hIcon:=IHandle;
    StrPCopy(szTip,'Свободное место на несменных дисках'); //всплывающая строка
  end;
  Shell_NotifyIcon(NIM_ADD,@NIData); //добавление значка
end;

procedure DeleteTrayIcon(Handle:HWND; n:Integer);
var NIData:TNotifyIconData;
begin
  with NIData do begin
    cbSize:=SizeOf(TNotifyIconData);
    Wnd:=Handle;
    uID:=n;
  end;
  Shell_NotifyIcon(NIM_DELETE,@NIData); //удаление значка
end;

end.

