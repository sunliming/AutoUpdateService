program JYUpdateService;

{$R *.res}

uses
  SysUtils,
  Service in 'Service.pas',
  slmlog in 'slmlog.pas',
  uUpdateService in 'uUpdateService.pas',
  uGlobal in 'uGlobal.pas',
  uDownloadFiles in 'uDownloadFiles.pas',
  jyDownloadFTPFile in 'jyDownloadFTPFile.pas',
  jyURLFunc in 'jyURLFunc.pas',
  md5 in 'MD5.pas',
  uSocket in 'uSocket.pas';

begin
  Main;
end.
