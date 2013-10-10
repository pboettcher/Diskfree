program Dskfre32;

uses
  Forms,Windows,
  Dskfree in 'Dskfree.pas' {Form1};

{$R *.RES}

begin
  Application.Initialize;
  Application.CreateForm(TForm1, Form1);
  Application.ShowMainForm:=False;
  Form1.Visible:=False;
  //Удалить кнопку на панели задач
  SetWindowLong(Application.Handle, GWL_EXSTYLE,
    getWindowLong(Application.Handle, GWL_EXSTYLE) or WS_EX_TOOLWINDOW) ;
  Application.Run;
end.

