unit uMain;

interface

procedure RestartService(const AServiceName: string; const AExeName: string);
procedure RestartJYAppUpdateService;

implementation

uses
  Windows, Psapi, SysUtils, StrUtils;

//var
//  strCurrPath: string;

{function GetCurrPath: string;
begin
  result := ExtractFilePath(Application.ExeName);
end;  }

{function WriteVBEFile: boolean;
var
  F: TextFile;
begin
  result := false;
  
  try
    AssignFile(F, Format('%sgetpids.vbe', [strCurrPath]));
    ReWrite(F);
    WriteLn(F, 'set fso=createobject("scripting.filesystemobject")');
    WriteLn(F, Format('if (fso.fileexists("%s~pids.txt")) then', [strCurrPath]));
    WriteLn(F, Format('  set file=fso.opentextfile("%s~pids.txt",2,true)', [strCurrPath]));
    WriteLn(F, 'else');
    WriteLn(F, Format('  set file=fso.createtextfile("%s~pids.txt",2,true)', [strCurrPath]));
    WriteLn(F, 'end if');
    WriteLn(F, 'wscript.echo "PID  ProcessName"');
    WriteLn(F, 'for each ps in getobject("winmgmts:\\.\root\cimv2:win32_process").instances_');
    WriteLn(F, 'wscript.echo ps.handle&vbtab&ps.name');
    WriteLn(F, 'file.writeline ps.handle&vbtab&ps.name');
    WriteLn(F, 'next');
    WriteLn(F, 'file.close');

    CloseFile(F);

    result := true;
  except
  end;
end; }

{function WriteBATFile: boolean;
var
  F: TextFile;
  s: string;
begin
  result := false;

  try
    AssignFile(F, Format('%sgetpids.bat', [strCurrPath]));
    ReWrite(F);
    s := Format('"%sgetpids.vbe"', [strCurrPath]);
    WriteLn(F, s);
    CloseFile(F);

    result := true;
  except
  end;
end;}

{function GetProcessPID(const AExeName: string): integer;
var
  F: TextFile;
  s: string;
begin
  result := -1;

  try
    if not FileExists(Format('%s~pids.txt', [strCurrPath])) then exit;

    AssignFile(F, Format('%s~pids.txt', [strCurrPath]));
    Reset(F);
    while not Eof(F) do
    begin
      ReadLn(F, s);
      s := Trim(LowerCase(s));
      if Pos(Trim(LowerCase(AExeName)), s) > 0 then
      begin
        result := StrToInt(LeftStr(s, Pos(' ', s)-1));
        break;
      end;
    end;
  except
  end;
end;  }

function GetExePID(const AExeName: string): int64;
var
  aProcesses: array[0..1023] of LongWord;
  cbNeeded: LongWord;
  i: integer;
  hProcess: THandle;
  hMod: HModule;
  BaseName: array[0..1023] of char;
  strBaseName: string;
begin
  result := -1;

  if not EnumProcesses(@aProcesses[0], sizeof(aProcesses), cbNeeded) then exit;

  for i:=0 to trunc(cbNeeded/sizeof(longword))-1 do
  begin
    if aProcesses[i] = 0 then continue;
    hProcess := OpenProcess(PROCESS_QUERY_INFORMATION or PROCESS_VM_READ, FALSE, aProcesses[i]);
    if hProcess > 0 then
    begin
      if EnumProcessModules(hProcess, @hMod, sizeof(hMod), cbNeeded) then
      begin
        ZeroMemory(@BaseName[0], 1024);
        GetModuleBaseName(hProcess, hMod, @BaseName[0], sizeof(BaseName));
        strBaseName := pchar(@BaseName[0]);
        strBaseName := Trim(LowerCase(strBaseName));
        if Pos(Trim(LowerCase(AExeName)), strBaseName) > 0 then
        begin
          result := aProcesses[i];
          break;
        end;
      end;
    end;
    CloseHandle(hProcess);
  end;
end;

procedure RestartService(const AServiceName: string; const AExeName: string);
var
  pid: integer;
begin
 { if not WriteVBEFile then exit;
  if not WriteBATFile then exit;

  DeleteFile(Format('%s~pids.txt', [strCurrPath]));
  if  WinExec(pchar(Format('"%sgetpids.bat"', [strCurrPath])), SW_HIDE) <= 31 then exit;
  pid := GetProcessPID(AExeName); }
  pid := GetExePID(AExeName);
  if pid > 0 then WinExec(PChar(format('ntsd -c q -p %d', [pid])), SW_HIDE);
  sleep(3000);
  WinExec(PChar(Format('net start %s', [AServiceName])), SW_HIDE);
end;

procedure RestartJYAppUpdateService;
begin
  RestartService('jyappupdateservice', 'JYUpdateService.exe');
end;





//initialization
//  strCurrPath := ExtractFilePath(Application.ExeName);

end.
