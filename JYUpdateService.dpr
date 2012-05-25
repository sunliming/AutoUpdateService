program JYUpdateService;

{$R *.res}

{$message 'É¾³ýËùÓÐMessageBox'}

uses
  SysUtils,
  Service in 'Service.pas',
  slmlog in 'slmlog.pas',
  ProgramVersion in 'ProgramVersion.pas',
  uUpdateService in 'uUpdateService.pas',
  uGlobal in 'uGlobal.pas',
  uDownloadFiles in 'uDownloadFiles.pas';

begin
  Main;
end.
