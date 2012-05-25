unit Service;

interface

uses windows;


procedure ServiceMain;

implementation

const
  SERVICE_WIN32_OWN_PROCESS   = $00000010;
  SERVICE_STOPPED             = $00000001;
  SERVICE_ACCEPT_STOP         = $00000001;

type
  TServiceStatus = record
    dwServiceType: DWORD;
    dwCurrentState: DWORD;
    dwControlsAccepted: DWORD;
    dwWin32ExitCode: DWORD;
    dwServiceSpecificExitCode: DWORD;
    dwCheckPoint: DWORD;
    dwWaitHint: DWORD;
  end;

  SERVICE_STATUS_HANDLE = THandle;

var
  hServiceStatus: SERVICE_STATUS_HANDLE;
  status: TServiceStatus;
  
//*********************************************************
// ³õÊ¼»¯º¯Êý
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

procedure ServiceMain;
begin
end;

end.
