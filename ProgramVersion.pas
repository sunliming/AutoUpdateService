unit ProgramVersion;

interface

function GetFileVersion(AFile: string): string;

implementation

uses Windows, SysUtils;

function GetFileVersion(AFile: string): string;
type
  PTranslate = ^TTranslate;
  TTranslate = record
    wLanguage: WORD;
    wCodePage: WORD;
  end;
var
  len: Cardinal;
  Zero: Cardinal;
  lpData: array of byte;
  lpTranslate: PTranslate;
  strValPath: string;
  pFileVersion: pchar;
begin
  result := '';
  if Pos('{FB82C789-CAB9-4016-BBE5-9089DBADDD5E}', AFile) > 0 then
  begin
    result := '{FB82C789-CAB9-4016-BBE5-9089DBADDD5E}';
    exit;
  end;
  try
    len := GetFileVersionInfoSize(pchar(AFile), Zero);
    if len <= 0 then exit;
    SetLength(lpData, len);
    if not GetFileVersionInfo(pchar(AFile), Zero, len, @lpData[0]) then exit;
    if not VerQueryValue(@lpData[0], '\VarFileInfo\Translation', Pointer(lpTranslate), len) then exit;
    strValPath := Format('\StringFileInfo\%.4x%.4x\FileVersion', [lpTranslate.wLanguage, lpTranslate.wCodePage]);
    if not VerQueryValue(@lpData[0], pchar(strValPath), Pointer(pFileVersion), len) then exit;
    result := pFileVersion;
  except
  end;
end;

end.
