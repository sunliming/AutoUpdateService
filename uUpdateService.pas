unit uUpdateService;

interface

procedure UpdateService(ANewFile, AServiceName: string);

implementation

uses Windows, SysUtils, JwaWinSvc, uGlobal, slmlog;

procedure UpdateService(ANewFile, AServiceName: string);
var
  F  : TextFile;
  hSCManager: THandle;
  hService: THandle;
  buf: array[0..4096-1] of byte;
  BytesNeeded: Cardinal;
  AppExeName: string;
  strBatFileLine: string;
begin
  //检测文件是否存在
  if not FileExists(ANewFile) then
  begin
    SaveToLogFile(Format(LOG_FILE, [FormatDateTime('yyyy-mm', now)]), Format('UpdateService(): File %s not exists.', [ANewFile]));
    exit;
  end;
  
  //获取本服务信息
  hSCManager := OpenSCManager(nil, nil, SC_MANAGER_ALL_ACCESS);
  if hSCManager = 0 then
  begin
    SaveToLogFile(Format(LOG_FILE, [FormatDateTime('yyyy-mm', now)]), 'UpdateService(): Can not Open SCManager.');
    exit;
  end;
  hService := OpenService(hSCManager, PChar(AServiceName), SERVICE_ALL_ACCESS);
  if hService = 0 then
  begin
    SaveToLogFile(Format(LOG_FILE, [FormatDateTime('yyyy-mm', now)]), 'UpdateService(): Can not Open Service.');
    exit;
  end;
  ZeroMemory(@buf[0], sizeof(buf));
  if not QueryServiceConfig(hService, @buf[0], sizeof(buf), BytesNeeded) then
  begin
    SaveToLogFile(Format(LOG_FILE, [FormatDateTime('yyyy-mm', now)]), Format('UpdateService(): QueryServiceConfig error: %d', [GetLastError]));
    exit;
  end;
  AppExeName := PQueryServiceConfig(@buf[0])^.lpBinaryPathName;
  
  //准备批处理文件
  SaveToLogFile(Format(LOG_FILE, [FormatDateTime('yyyy-mm', now)]), '准备批处理文件...');
  AssignFile(F, ExtractFilePath(AppExeName) + UPDATE_BAT_FILE);
  ReWrite(F);
  strBatFileLine := 'net stop ' + AServiceName;
  SaveToLogFile(Format(LOG_FILE, [FormatDateTime('yyyy-mm', now)]), Format('|  %s', [strBatFileLine]));
  WriteLn(F, strBatFileLine);
  strBatFileLine := Format('copy "%s" "%s" /y >> ' + LOG_FILE, [ANewFile, AppExeName, FormatDateTime('yyyy-mm', now)]);
  SaveToLogFile(Format(LOG_FILE, [FormatDateTime('yyyy-mm', now)]), Format('|  %s', [strBatFileLine]));
  WriteLn(F, strBatFileLine);
  strBatFileLine := Format('del "%s"', [ANewFile]);
  SaveToLogFile(Format(LOG_FILE, [FormatDateTime('yyyy-mm', now)]), Format('|  %s', [strBatFileLine]));
  WriteLn(F, strBatFileLine);
  strBatFileLine := 'net start ' + AServiceName;
  SaveToLogFile(Format(LOG_FILE, [FormatDateTime('yyyy-mm', now)]), Format('|  %s', [strBatFileLine]));
  WriteLn(F, strBatFileLine);
  strBatFileLine := Format('del "%s%s"', [ExtractFilePath(AppExeName), UPDATE_BAT_FILE]);
  SaveToLogFile(Format(LOG_FILE, [FormatDateTime('yyyy-mm', now)]), Format('|  %s', [strBatFileLine]));
  WriteLn(F, strBatFileLine);
  CloseFile(F);

  //执行批处理文件
  SaveToLogFile(Format(LOG_FILE, [FormatDateTime('yyyy-mm', now)]), '执行批处理文件...');
  //WinExec(PChar(ExtractFilePath(AppExeName) + UPDATE_BAT_FILE + ' >> ' + Format(LOG_FILE, [FormatDateTime('yyyy-mm', now)])), SW_HIDE);
  WinExec(PChar(Format('"%s%s"', [ExtractFilePath(AppExeName), UPDATE_BAT_FILE])), SW_HIDE);
end;

end.
