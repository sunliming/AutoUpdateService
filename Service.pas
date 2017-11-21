unit Service;

interface

procedure Main;

implementation

uses StrUtils, Windows, Messages, SysUtils, JwaWinSvc, JwaWinNT, slmlog,
  uGlobal, uUpdateService, uDownloadFiles, uFileVersionProc, uSocket;

var
  hServiceStatus: SERVICE_STATUS_HANDLE;
  status: TServiceStatus;
  dwThreadID: DWORD;

//*********************************************************
// 初始化函数
//*********************************************************
procedure Init;
begin
    hServiceStatus := 0;
    status.dwServiceType := SERVICE_WIN32_OWN_PROCESS;
    status.dwCurrentState := SERVICE_STOPPED;
    status.dwControlsAccepted := SERVICE_ACCEPT_STOP;
    status.dwWin32ExitCode := 0;
    status.dwServiceSpecificExitCode := 0;
    status.dwCheckPoint := 0;
    status.dwWaitHint := 0;
end;

procedure LogEvent(AMsg: string);
begin
end;

function IsInstalled: boolean;
var
  hSCM: SC_HANDLE;
  hService: SC_HANDLE;
begin
  result := false;

  //打开服务控制管理器
  hSCM := OpenSCManager(nil, nil, SC_MANAGER_ALL_ACCESS);

  if (hSCM <> 0) then
  begin
    //打开服务
    hService := OpenService(hSCM, SERVICE_NAME, SERVICE_QUERY_CONFIG);
    if (hService <> 0) then
    begin
      result := true;
      CloseServiceHandle(hService);
    end;
    CloseServiceHandle(hSCM);
  end;
end;

function install: boolean;
var
  hSCM: SC_HANDLE;
  hService: SC_HANDLE;
  szFilePath: array[0..MAX_PATH-1] of char;
begin
  result := false;

  if IsInstalled then
  begin
    SaveToLogFile(Format(LOG_FILE, [FormatDateTime('yyyy-mm', now)]), 'Install(): 服务已经存在.');
    result := true;
    exit;
  end;

  //打开服务控制管理器
  hSCM := OpenSCManager(nil, nil, SC_MANAGER_ALL_ACCESS);
  if hSCM = 0 then
  begin
    SaveToLogFile(Format(LOG_FILE, [FormatDateTime('yyyy-mm', now)]), 'Install(): Couldn''t open service manager.');
    exit;
  end;

  // Get the executable file path
  ZeroMemory(@szFilePath[0], sizeof(szFilePath));
  GetModuleFileName(0, szFilePath, MAX_PATH);

  //创建服务
  hService := CreateService(hSCM, SERVICE_NAME, SERVICE_NAME, SERVICE_ALL_ACCESS, SERVICE_WIN32_OWN_PROCESS, SERVICE_AUTO_START, SERVICE_ERROR_NORMAL, szFilePath, nil, nil, '', nil, nil);
  if (hService = 0) then
  begin
    CloseServiceHandle(hSCM);
    SaveToLogFile(Format(LOG_FILE, [FormatDateTime('yyyy-mm', now)]), 'Install(): Couldn''t create service.');
    exit;
  end;

  //启动服务
  if not StartService(hService, 0, nil) then
  begin
    SaveToLogFile(Format(LOG_FILE, [FormatDateTime('yyyy-mm', now)]), 'Install(): Couldn''t Start service.');
  end;

  CloseServiceHandle(hService);
  CloseServiceHandle(hSCM);

  SaveToLogFile(Format(LOG_FILE, [FormatDateTime('yyyy-mm', now)]), Format('Install(): 服务安装成功. 执行文件版本:%s', [GetFileVersion(PChar(@szFilePath[0]))]));
  result := true;
end;

function uninstall: boolean;
var
  hSCM: SC_HANDLE;
  hService: SC_HANDLE;
  ssStatus: TServiceStatus;
  bDelete: LongBool;
begin
  result := false;
  
  if (not IsInstalled) then
  begin
    SaveToLogFile(Format(LOG_FILE, [FormatDateTime('yyyy-mm', now)]), 'uninstall(): 服务未安装，无需卸载.');
    result := true;
    exit;
  end;

  hSCM := OpenSCManager(nil, nil, SC_MANAGER_ALL_ACCESS);
  if (hSCM = 0) then
  begin
    SaveToLogFile(Format(LOG_FILE, [FormatDateTime('yyyy-mm', now)]), 'uninstall(): Couldn''t open service manager');
    exit;
  end;

  hService := OpenService(hSCM, SERVICE_NAME, SERVICE_STOP or DELETE);
  if (hService = 0) then
  begin
    CloseServiceHandle(hSCM);
    SaveToLogFile(Format(LOG_FILE, [FormatDateTime('yyyy-mm', now)]), 'uninstall(): Couldn''t open service');
    exit;
  end;

  ControlService(hService, SERVICE_CONTROL_STOP, ssStatus);

  //删除服务
  bDelete := DeleteService(hService);
  CloseServiceHandle(hService);
  CloseServiceHandle(hSCM);

  if (not bDelete) then
  begin
    SaveToLogFile(Format(LOG_FILE, [FormatDateTime('yyyy-mm', now)]), 'uninstall(): Service could not be deleted');
    LogEvent('Service could not be deleted');
    exit;
  end;

  SaveToLogFile(Format(LOG_FILE, [FormatDateTime('yyyy-mm', now)]), 'uninstall(): 服务卸载成功.');
  result := true;
end;

procedure ServiceStrl(dwOpcode: DWORD); stdcall;
begin
  case dwOpcode of
    SERVICE_CONTROL_STOP: begin
      SaveToLogFile(Format(LOG_FILE, [FormatDateTime('yyyy-mm', now)]), 'ServiceStrl(): SERVICE_CONTROL_STOP');
      status.dwCurrentState := SERVICE_STOP_PENDING;
      SetServiceStatus(hServiceStatus, status);
      PostThreadMessage(dwThreadID, WM_CLOSE, 0, 0);
    end;
    SERVICE_CONTROL_PAUSE: begin
      SaveToLogFile(Format(LOG_FILE, [FormatDateTime('yyyy-mm', now)]), 'ServiceStrl(): SERVICE_CONTROL_PAUSE');
    end;
    SERVICE_CONTROL_CONTINUE: begin
      SaveToLogFile(Format(LOG_FILE, [FormatDateTime('yyyy-mm', now)]), 'ServiceStrl(): SERVICE_CONTROL_CONTINUE');
    end;
    SERVICE_CONTROL_INTERROGATE: begin
      SaveToLogFile(Format(LOG_FILE, [FormatDateTime('yyyy-mm', now)]), 'ServiceStrl(): SERVICE_CONTROL_INTERROGATE');
    end;
    SERVICE_CONTROL_SHUTDOWN: begin
      SaveToLogFile(Format(LOG_FILE, [FormatDateTime('yyyy-mm', now)]), 'ServiceStrl(): SERVICE_CONTROL_SHUTDOWN');
    end;
    else begin
      SaveToLogFile(Format(LOG_FILE, [FormatDateTime('yyyy-mm', now)]), 'ServiceStrl(): Bad service request');
      LogEvent('Bad service request');
    end;
  end;
end;

procedure ServiceMain(dwNumServicesArgs: DWORD; lpServiceArgVectors: LPSTR); stdcall;
var
  szFilePath: array[0..MAX_PATH-1] of char;
  iTimer: integer;
begin
  ZeroMemory(@szFilePath[0], sizeof(szFilePath));
  GetModuleFileName(0, szFilePath, MAX_PATH);
  SaveToLogFile(Format(LOG_FILE, [FormatDateTime('yyyy-mm', now)]), '------------------------------------------------------------------------');
  SaveToLogFile(Format(LOG_FILE, [FormatDateTime('yyyy-mm', now)]), Format('ServiceMain(): 程序版本: %s', [GetFileVersion(PChar(@szFilePath[0]))]));
  SaveToLogFile(Format(LOG_FILE, [FormatDateTime('yyyy-mm', now)]), 'ServiceMain(): Starting...');

  // Register the control request handler
  status.dwCurrentState := SERVICE_START_PENDING;
  status.dwControlsAccepted := SERVICE_ACCEPT_STOP;

  //注册服务控制
  hServiceStatus := RegisterServiceCtrlHandler(SERVICE_NAME, @ServiceStrl);
  if (hServiceStatus = 0) then
  begin
    SaveToLogFile(Format(LOG_FILE, [FormatDateTime('yyyy-mm', now)]), 'ServiceMain(): Handler not installed.');
    LogEvent('Handler not installed');
    exit;
  end;
  SetServiceStatus(hServiceStatus, status);

  status.dwWin32ExitCode := S_OK;
  status.dwCheckPoint := 0;
  status.dwWaitHint := 0;
  status.dwCurrentState := SERVICE_RUNNING;
  SetServiceStatus(hServiceStatus, status);

  //模拟服务的运行，10秒后自动退出。应用时将主要任务放于此即可
  SaveToLogFile(Format(LOG_FILE, [FormatDateTime('yyyy-mm', now)]), 'ServiceMain(): Started.');

  //InitTCPSocket; //开启socket侦听

  //StatusEchoInit;  //开启UDP 侦听

  iTimer := 1;
  while (status.dwCurrentState = SERVICE_RUNNING) do
  begin
    Dec(iTimer);
    if iTimer <= 0 then
    begin
      DownloadAndUpdate;
      iTimer := 3600;
    end;
    Sleep(1000);
  end;

  //FreeTCPSocket; 
  //StatusEchoFree;

  SaveToLogFile(Format(LOG_FILE, [FormatDateTime('yyyy-mm', now)]), 'ServiceMain(): Stop.');
  status.dwCurrentState := SERVICE_STOPPED;
  SetServiceStatus(hServiceStatus, status);
  LogEvent('Service stopped');
end;

procedure Main;
var
  st: array[0..1] of TServiceTableEntry;
begin
  Init;

  dwThreadID := GetCurrentThreadId;

  st[0].lpServiceName := SERVICE_NAME;
  st[0].lpServiceProc := @ServiceMain;
  st[1].lpServiceName := nil;
  st[1].lpServiceProc := nil;

  if FindCmdLineSwitch('install', ['/', '-'], true) then
  begin
    SaveToLogFile(Format(LOG_FILE, [FormatDateTime('yyyy-mm', now)]), '');
    SaveToLogFile(Format(LOG_FILE, [FormatDateTime('yyyy-mm', now)]), '========================================================================');
    SaveToLogFile(Format(LOG_FILE, [FormatDateTime('yyyy-mm', now)]), 'Main(): install');
    install;
  end
  else if FindCmdLineSwitch('uninstall', ['/', '-'], true) then
  begin
    SaveToLogFile(Format(LOG_FILE, [FormatDateTime('yyyy-mm', now)]), 'Main(): uninstall');
    uninstall;
  end
  else if not StartServiceCtrlDispatcher(@st[0]) then
  begin
    SaveToLogFile(Format(LOG_FILE, [FormatDateTime('yyyy-mm', now)]), 'Main(): Register Service Main Function Error!');
    LogEvent('Register Service Main Function Error!');
  end;
end;

end.
