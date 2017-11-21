unit uUpdateService;

interface

function UpdateService(ANewFile, AServiceName: string): boolean;
function GetServiceAppPath(AServiceName: string): string;
function GetServiceVersion(AServiceName: string): string;

implementation

uses Windows, SysUtils, JwaWinSvc, uGlobal, slmlog, uFileVersionProc;

function UpdateService(ANewFile, AServiceName: string): boolean;
var
  F  : TextFile;
  AppExeName: string;
  strBatFileLine: string;
begin
  result := false;
  
  //检测文件是否存在
  if not FileExists(ANewFile) then
  begin
    SaveToLogFile(Format(LOG_FILE, [FormatDateTime('yyyy-mm', now)]), Format('UpdateService(): File %s not exists.', [ANewFile]));
    exit;
  end;
  
  //获取服务信息
  AppExeName := GetServiceAppPath(AServiceName);

  //比较版本
  if VersionCheck(GetFileVersion(ANewFile), GetFileVersion(AppExeName)) <= 0 then
  begin
    SaveToLogFile(Format(LOG_FILE, [FormatDateTime('yyyy-mm', now)]), Format('UpdateService(): Skip Update,  %s Have a new Version', [AServiceName]));
    DeleteFile(ANewFile);
    exit;
  end;
  
  //准备批处理文件
  SaveToLogFile(Format(LOG_FILE, [FormatDateTime('yyyy-mm', now)]), '准备批处理文件...');
  AssignFile(F, CACHE_PATH + UPDATE_BAT_FILE);
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
  strBatFileLine := Format('del "%s%s"', [CACHE_PATH, UPDATE_BAT_FILE]);
  SaveToLogFile(Format(LOG_FILE, [FormatDateTime('yyyy-mm', now)]), Format('|  %s', [strBatFileLine]));
  WriteLn(F, strBatFileLine);
  CloseFile(F);

  //执行批处理文件
  SaveToLogFile(Format(LOG_FILE, [FormatDateTime('yyyy-mm', now)]), '执行批处理文件...');
  //WinExec(PChar(ExtractFilePath(AppExeName) + UPDATE_BAT_FILE + ' >> ' + Format(LOG_FILE, [FormatDateTime('yyyy-mm', now)])), SW_HIDE);
  WinExec(PChar(Format('"%s%s"', [CACHE_PATH, UPDATE_BAT_FILE])), SW_HIDE);

  result := true;
end;

function GetServiceAppPath(AServiceName: string): string;
var
  hSCManager: THandle;
  hService: THandle;
  buf: array[0..4096-1] of byte;
  BytesNeeded: Cardinal;
begin
  result := '';

  hSCManager := OpenSCManager(nil, nil, SC_MANAGER_ALL_ACCESS);
  if hSCManager = 0 then exit;
  hService := OpenService(hSCManager, PChar(AServiceName), SERVICE_ALL_ACCESS);
  if hService = 0 then exit;
  ZeroMemory(@buf[0], sizeof(buf));
  if not QueryServiceConfig(hService, @buf[0], sizeof(buf), BytesNeeded) then exit;
  result := PQueryServiceConfig(@buf[0])^.lpBinaryPathName;
end;

function GetServiceVersion(AServiceName: string): string;
begin
  result := GetFileVersion(GetServiceAppPath(AServiceName));
end;

end.
