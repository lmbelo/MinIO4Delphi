program MinIOSample1;

uses
  Vcl.Forms,
  Main.Form in 'Main.Form.pas' {MainForm};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
