unit uUpdateService;

interface

implementation

uses JwaWinSvc, uGlobal;

procedure UpdateService(AOldFile, ANewFile, AServiceName: string);
var
  F  : TextFile;
  hSCManager: THandle;
  hService: THandle;
  qsc: TQueryServiceConfig;
  BytesNeeded: Cardinal;
  AppExeName: string;
begin
  //获取本服务信息
  hSCManager := OpenSCManager(nil, nil, SC_MANAGER_ALL_ACCESS);
  if hSCManager = 0 then exit;
  hService := OpenService(hSCManager, PChar(AServiceName), SERVICE_ALL_ACCESS);
  if hService = 0 then exit;
  if not QueryServiceConfig(hService, @qsc, sizeof(qsc), BytesNeeded) then exit;
  AppExeName := qsc.lpBinaryPathName;
  
  //准备批处理文件
  AssignFile(F, ExtractFilePath(AppExeName) + 'UpdateAndRestartService.bat');
  ReWrite(F);
  WriteLn(F, 'net stop ' + ThisServiceDisplayName);
  WriteLn(F, 'del ' + AppExeName);
  WriteLn(F, 'ren ' + ANewFileName + ' ' + ExtractFileName(AppExeName));
  WriteLn(F, 'net start ' + ThisServiceDisplayName);
  CloseFile(F);

  //执行批处理文件
  WinExec(PChar(ExtractFilePath(AppExeName) + 'UpdateAndRestartService.bat'), SW_HIDE);
end;

end.
