unit Service;

interface

procedure Main;

implementation

uses Windows, Messages, SysUtils, JwaWinSvc, JwaWinNT;

const
  SERVICE_NAME = 'JYAppUpdateService';

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
    result := true;
    exit;
  end;

  //打开服务控制管理器
  hSCM := OpenSCManager(nil, nil, SC_MANAGER_ALL_ACCESS);
  if hSCM = 0 then
  begin
    MessageBox(0, 'Couldn''t open service manager', SERVICE_NAME, MB_OK);
    exit;
  end;

  // Get the executable file path
  ZeroMemory(@szFilePath[0], sizeof(szFilePath));
  GetModuleFileName(0, szFilePath, MAX_PATH);

  //创建服务
  hService := CreateService(hSCM, SERVICE_NAME, SERVICE_NAME, SERVICE_ALL_ACCESS, SERVICE_WIN32_OWN_PROCESS, SERVICE_DEMAND_START, SERVICE_ERROR_NORMAL, szFilePath, nil, nil, '', nil, nil);
  if (hService = 0) then
  begin
    CloseServiceHandle(hSCM);
    MessageBox(0, 'Couldn''t create service', SERVICE_NAME, MB_OK);
    exit;
  end;

  CloseServiceHandle(hService);
  CloseServiceHandle(hSCM);

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
    result := true;
    exit;
  end;

  hSCM := OpenSCManager(nil, nil, SC_MANAGER_ALL_ACCESS);
  if (hSCM = 0) then
  begin
    MessageBox(0, 'Couldn''t open service manager', SERVICE_NAME, MB_OK);
    exit;
  end;

  hService := OpenService(hSCM, SERVICE_NAME, SERVICE_STOP or DELETE);
  if (hService = 0) then
  begin
    CloseServiceHandle(hSCM);
    MessageBox(0, 'Couldn''t open service', SERVICE_NAME, MB_OK);
    exit;
  end;

  ControlService(hService, SERVICE_CONTROL_STOP, ssStatus);

  //删除服务
  bDelete := DeleteService(hService);
  CloseServiceHandle(hService);
  CloseServiceHandle(hSCM);

  if (bDelete) then
  begin
    result := true;
    exit;
  end;

  if (not bDelete) then
  begin
    LogEvent('Service could not be deleted');
    exit;
  end;

  result := true;
end;

procedure ServiceStrl(dwOpcode: DWORD); stdcall;
begin
  case dwOpcode of
    SERVICE_CONTROL_STOP: begin
      status.dwCurrentState := SERVICE_STOP_PENDING;
      SetServiceStatus(hServiceStatus, status);
      PostThreadMessage(dwThreadID, WM_CLOSE, 0, 0);
    end;
    SERVICE_CONTROL_PAUSE: begin
    end;
    SERVICE_CONTROL_CONTINUE: begin
    end;
    SERVICE_CONTROL_INTERROGATE: begin
    end;
    SERVICE_CONTROL_SHUTDOWN: begin
    end;
    else begin
      LogEvent('Bad service request');
    end;
  end;
end;

procedure ServiceMain(dwNumServicesArgs: DWORD; lpServiceArgVectors: LPSTR); stdcall;
var
  i: integer;
begin
  // Register the control request handler
  status.dwCurrentState := SERVICE_START_PENDING;
  status.dwControlsAccepted := SERVICE_ACCEPT_STOP;

  //注册服务控制
  hServiceStatus := RegisterServiceCtrlHandler(SERVICE_NAME, @ServiceStrl);
  if (hServiceStatus = 0) then
  begin
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
  i := 0;
  while (i < 100) and (status.dwCurrentState = SERVICE_RUNNING) do
  begin
    Sleep(1000);
    Inc(i);
  end;

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

  if FindCmdLineSwitch('install', ['/', '-'], true) then install
  else if FindCmdLineSwitch('uninstall', ['/', '-'], true) then uninstall
  else if not StartServiceCtrlDispatcher(@st[0]) then LogEvent('Register Service Main Function Error!');
end;

end.
