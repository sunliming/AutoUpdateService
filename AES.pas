(**************************************************)
(*                                                *)
(*     Advanced Encryption Standard (AES)         *)
(*     Interface Unit v1.3                        *)
(*                                                *)
(*                                                *)
(*     Copyright (c) 2002 Jorlen Young            *)
(*                                                *)
(*                                                *)
(*                                                *)
(*说明：                                          *)
(*                                                *)
(*   基于 ElASE.pas 单元封装                      *)
(*                                                *)
(*   这是一个 AES 加密算法的标准接口。            *)
(*                                                *)
(*                                                *)
(*   作者：杨泽晖      2004.12.04                 *)
(*                                                *)
(*   支持 128 / 192 / 256 位的密匙                *)                
(*   默认情况下按照 128 位密匙操作                *)
(*                                                *)
(**************************************************)

{$H+}
unit AES;

// 2012-03-20   add  xe  开启标识 DELPHIXE 定义 
//支持 delphi 6 - xe2 
{.$DEFINE  DELPHIXE}

interface

uses
  SysUtils, Classes, Math, ElAES, EncdDecd;

type
  TKeyBit = (kb128, kb192, kb256);
  {
    TStringStream = class(TStream)
    private
    FDataString: string;
    FPosition: Integer;
    protected
    procedure SetSize(NewSize: Longint); override;
    public
    constructor Create(const AString: string);
    function Read(var Buffer; Count: Longint): Longint; override;
    function ReadString(Count: Longint): string;
    function Seek(Offset: Longint; Origin: Word): Longint; override;
    function Write(const Buffer; Count: Longint): Longint; override;
    procedure WriteString(const AString: string);
    property DataString: string read FDataString;
    end;
  }
function StrToHex(Value: AnsiString): AnsiString;
function HexToStr(Value: AnsiString): AnsiString;
function EncryptString(Value: AnsiString; Key: AnsiString;
  KeyBit: TKeyBit = kb128): AnsiString;
function DecryptString(Value: AnsiString; Key: AnsiString;
  KeyBit: TKeyBit = kb128): AnsiString;
function EncryptStream(Stream: TStream; Key: AnsiString;
  KeyBit: TKeyBit = kb128): TStream;
function DecryptStream(Stream: TStream; Key: AnsiString;
  KeyBit: TKeyBit = kb128): TStream;
procedure EncryptFile(SourceFile, DestFile: AnsiString; Key: AnsiString;
  KeyBit: TKeyBit = kb128);
procedure DecryptFile(SourceFile, DestFile: AnsiString; Key: AnsiString;
  KeyBit: TKeyBit = kb128);

implementation

{
  constructor TStringStream.Create(const AString: string);
  begin
  inherited Create;
  FDataString := AString;
  end;

  function TStringStream.Read(var Buffer; Count: Longint): Longint;
  begin
  Result := Length(FDataString) - FPosition;
  if Result > Count then Result := Count;
  Move(PChar(@FDataString[FPosition + SizeOf(Char)])^, Buffer, Result * SizeOf(Char));
  Inc(FPosition, Result);
  end;

  function TStringStream.Write(const Buffer; Count: Longint): Longint;
  begin
  Result := Count;
  SetLength(FDataString, (FPosition + Result));
  Move(Buffer, PChar(@FDataString[FPosition + SizeOf(Char)])^, Result * SizeOf(Char));
  Inc(FPosition, Result);
  end;

  function TStringStream.Seek(Offset: Longint; Origin: Word): Longint;
  begin
  case Origin of
  soFromBeginning: FPosition := Offset;
  soFromCurrent: FPosition := FPosition + Offset;
  soFromEnd: FPosition := Length(FDataString) - Offset;
  end;
  if FPosition > Length(FDataString) then
  FPosition := Length(FDataString)
  else if FPosition < 0 then FPosition := 0;
  Result := FPosition;
  end;

  function TStringStream.ReadString(Count: Longint): string;
  var
  Len: Integer;
  begin
  Len := Length(FDataString) - FPosition;
  if Len > Count then Len := Count;
  SetString(Result, PChar(@FDataString[FPosition + SizeOf(Char)]), Len);
  Inc(FPosition, Len);
  end;

  procedure TStringStream.WriteString(const AString: string);
  begin
  Write(PChar(AString)^, Length(AString));
  end;

  procedure TStringStream.SetSize(NewSize: Longint);
  begin
  SetLength(FDataString, NewSize);
  if FPosition > NewSize then FPosition := NewSize;
  end;
}

function StrToHex(Value: AnsiString): AnsiString;
var
  I: Integer;
begin
  Result := '';
  for I := 1 to Length(Value) do
    Result := Result + IntToHex(ord(Value[I]), 2);
end;

function HexToStr(Value: AnsiString): AnsiString;
var
  I: Integer;
begin
  Result := '';
  for I := 1 to Length(Value) do
  begin
    if ((I mod 2) = 1) then
    begin
      Result := Result + ansichar(StrToInt('0x' + Copy(Value, I, 2)));
    end;
  end;
end;

{ --  字符串加密函数 默认按照 128 位密匙加密 -- }
function EncryptString(Value: AnsiString; Key: AnsiString;
  KeyBit: TKeyBit = kb128): AnsiString;
var
  SS, DS: TStringStream;
  AESKey128: TAESKey128;
  AESKey192: TAESKey192;
  AESKey256: TAESKey256;
  //I: Integer;
  s: AnsiString;
begin
  Result := '';
  SS := TStringStream.Create(Value); // ,TEncoding.ASCII);
  DS := TStringStream.Create(''); // ,TEncoding.ASCII);
  try
    { --  128 位密匙最大长度为 16 个字符 -- }
    if KeyBit = kb128 then
    begin
      FillChar(AESKey128, SizeOf(AESKey128), 0);
      Move(PChar(Key)^, AESKey128, Min(SizeOf(AESKey128), Length(Key)));
      EncryptAESStreamECB(SS, 0, AESKey128, DS);
    end;
    { --  192 位密匙最大长度为 24 个字符 -- }
    if KeyBit = kb192 then
    begin
      FillChar(AESKey192, SizeOf(AESKey192), 0);
      Move(PChar(Key)^, AESKey192, Min(SizeOf(AESKey192), Length(Key)));
      EncryptAESStreamECB(SS, 0, AESKey192, DS);
    end;
    { --  256 位密匙最大长度为 32 个字符 -- }
    if KeyBit = kb256 then
    begin
      FillChar(AESKey256, SizeOf(AESKey256), 0);
      Move(PChar(Key)^, AESKey256, Min(SizeOf(AESKey256), Length(Key)));
      EncryptAESStreamECB(SS, 0, AESKey256, DS);
    end;
    s := '';

    {$IFDEF DELPHIXE}
      if High(DS.Bytes) > 0 then
      begin
        for I := 0 to High(DS.Bytes) do
        begin
          s := s + IntToHex(DS.Bytes[I], 2);
        end;
      end;
    {$ELSE}
      s := StrToHex(DS.DataString);
    {$ENDIF}
    
    Result := (s);
  finally
    SS.Free;
    DS.Free;
  end;
end;

{ --  字符串解密函数 默认按照 128 位密匙解密 -- }
function DecryptString(Value: AnsiString; Key: AnsiString;
  KeyBit: TKeyBit = kb128): AnsiString;
var
  SS, DS: TStringStream;
  AESKey128: TAESKey128;
  AESKey192: TAESKey192;
  AESKey256: TAESKey256;
begin
  Result := '';
  SS := TStringStream.Create(HexToStr(Value));
  DS := TStringStream.Create('');
  try
    // SS.ReadBuffer(Size, SizeOf(Size));
    { --  128 位密匙最大长度为 16 个字符 -- }
    if KeyBit = kb128 then
    begin
      FillChar(AESKey128, SizeOf(AESKey128), 0);
      Move(PChar(Key)^, AESKey128, Min(SizeOf(AESKey128), Length(Key)));
      DecryptAESStreamECB(SS, SS.Size - SS.Position, AESKey128, DS);
    end;
    { --  192 位密匙最大长度为 24 个字符 -- }
    if KeyBit = kb192 then
    begin
      FillChar(AESKey192, SizeOf(AESKey192), 0);
      Move(PChar(Key)^, AESKey192, Min(SizeOf(AESKey192), Length(Key)));
      DecryptAESStreamECB(SS, SS.Size - SS.Position, AESKey192, DS);
    end;
    { --  256 位密匙最大长度为 32 个字符 -- }
    if KeyBit = kb256 then
    begin
      FillChar(AESKey256, SizeOf(AESKey256), 0);
      Move(PChar(Key)^, AESKey256, Min(SizeOf(AESKey256), Length(Key)));
      DecryptAESStreamECB(SS, SS.Size - SS.Position, AESKey256, DS);
    end;
    Result := DS.DataString;
  finally
    SS.Free;
    DS.Free;
  end;
end;

{ --  流加密函数 默认按照 128 位密匙解密 -- }
function EncryptStream(Stream: TStream; Key: AnsiString;
  KeyBit: TKeyBit = kb128): TStream;
var
  Count: Int64;
  OutStrm: TStream;
  AESKey128: TAESKey128;
  AESKey192: TAESKey192;
  AESKey256: TAESKey256;
begin
  OutStrm := TStream.Create;
  Stream.Position := 0;
  Count := Stream.Size;
  OutStrm.Write(Count, SizeOf(Count));
  try
    { --  128 位密匙最大长度为 16 个字符 -- }
    if KeyBit = kb128 then
    begin
      FillChar(AESKey128, SizeOf(AESKey128), 0);
      Move(PChar(Key)^, AESKey128, Min(SizeOf(AESKey128), Length(Key)));
      EncryptAESStreamECB(Stream, 0, AESKey128, OutStrm);
    end;
    { --  192 位密匙最大长度为 24 个字符 -- }
    if KeyBit = kb192 then
    begin
      FillChar(AESKey192, SizeOf(AESKey192), 0);
      Move(PChar(Key)^, AESKey192, Min(SizeOf(AESKey192), Length(Key)));
      EncryptAESStreamECB(Stream, 0, AESKey192, OutStrm);
    end;
    { --  256 位密匙最大长度为 32 个字符 -- }
    if KeyBit = kb256 then
    begin
      FillChar(AESKey256, SizeOf(AESKey256), 0);
      Move(PChar(Key)^, AESKey256, Min(SizeOf(AESKey256), Length(Key)));
      EncryptAESStreamECB(Stream, 0, AESKey256, OutStrm);
    end;
    Result := OutStrm;
  finally
    OutStrm.Free;
  end;
end;

{ --  流解密函数 默认按照 128 位密匙解密 -- }
function DecryptStream(Stream: TStream; Key: AnsiString;
  KeyBit: TKeyBit = kb128): TStream;
var
  Count, OutPos: Int64;
  OutStrm: TStream;
  AESKey128: TAESKey128;
  AESKey192: TAESKey192;
  AESKey256: TAESKey256;
begin
  OutStrm := TStream.Create;
  Stream.Position := 0;
  OutPos := OutStrm.Position;
  Stream.ReadBuffer(Count, SizeOf(Count));
  try
    { --  128 位密匙最大长度为 16 个字符 -- }
    if KeyBit = kb128 then
    begin
      FillChar(AESKey128, SizeOf(AESKey128), 0);
      Move(PChar(Key)^, AESKey128, Min(SizeOf(AESKey128), Length(Key)));
      DecryptAESStreamECB(Stream, Stream.Size - Stream.Position, AESKey128,
        OutStrm);
    end;
    { --  192 位密匙最大长度为 24 个字符 -- }
    if KeyBit = kb192 then
    begin
      FillChar(AESKey192, SizeOf(AESKey192), 0);
      Move(PChar(Key)^, AESKey192, Min(SizeOf(AESKey192), Length(Key)));
      DecryptAESStreamECB(Stream, Stream.Size - Stream.Position, AESKey192,
        OutStrm);
    end;
    { --  256 位密匙最大长度为 32 个字符 -- }
    if KeyBit = kb256 then
    begin
      FillChar(AESKey256, SizeOf(AESKey256), 0);
      Move(PChar(Key)^, AESKey256, Min(SizeOf(AESKey256), Length(Key)));
      DecryptAESStreamECB(Stream, Stream.Size - Stream.Position, AESKey256,
        OutStrm);
    end;
    OutStrm.Size := OutPos + Count;
    OutStrm.Position := OutPos;
    Result := OutStrm;
  finally
    OutStrm.Free;
  end;
end;

{ --  文件加密函数 默认按照 128 位密匙解密 -- }
procedure EncryptFile(SourceFile, DestFile: AnsiString; Key: AnsiString;
  KeyBit: TKeyBit = kb128);
var
  SFS, DFS: TFileStream;
  Size: Int64;
  AESKey128: TAESKey128;
  AESKey192: TAESKey192;
  AESKey256: TAESKey256;
begin
  SFS := TFileStream.Create(SourceFile, fmOpenRead);
  try
    DFS := TFileStream.Create(DestFile, fmCreate);
    try
      Size := SFS.Size;
      DFS.WriteBuffer(Size, SizeOf(Size));
      { --  128 位密匙最大长度为 16 个字符 -- }
      if KeyBit = kb128 then
      begin
        FillChar(AESKey128, SizeOf(AESKey128), 0);
        Move(PChar(Key)^, AESKey128, Min(SizeOf(AESKey128), Length(Key)));
        EncryptAESStreamECB(SFS, 0, AESKey128, DFS);
      end;
      { --  192 位密匙最大长度为 24 个字符 -- }
      if KeyBit = kb192 then
      begin
        FillChar(AESKey192, SizeOf(AESKey192), 0);
        Move(PChar(Key)^, AESKey192, Min(SizeOf(AESKey192), Length(Key)));
        EncryptAESStreamECB(SFS, 0, AESKey192, DFS);
      end;
      { --  256 位密匙最大长度为 32 个字符 -- }
      if KeyBit = kb256 then
      begin
        FillChar(AESKey256, SizeOf(AESKey256), 0);
        Move(PChar(Key)^, AESKey256, Min(SizeOf(AESKey256), Length(Key)));
        EncryptAESStreamECB(SFS, 0, AESKey256, DFS);
      end;
    finally
      DFS.Free;
    end;
  finally
    SFS.Free;
  end;
end;

{ --  文件解密函数 默认按照 128 位密匙解密 -- }
procedure DecryptFile(SourceFile, DestFile: AnsiString; Key: AnsiString;
  KeyBit: TKeyBit = kb128);
var
  SFS, DFS: TFileStream;
  Size: Int64;
  AESKey128: TAESKey128;
  AESKey192: TAESKey192;
  AESKey256: TAESKey256;
begin
  SFS := TFileStream.Create(SourceFile, fmOpenRead);
  try
    SFS.ReadBuffer(Size, SizeOf(Size));
    DFS := TFileStream.Create(DestFile, fmCreate);
    try
      { --  128 位密匙最大长度为 16 个字符 -- }
      if KeyBit = kb128 then
      begin
        FillChar(AESKey128, SizeOf(AESKey128), 0);
        Move(PChar(Key)^, AESKey128, Min(SizeOf(AESKey128), Length(Key)));
        DecryptAESStreamECB(SFS, SFS.Size - SFS.Position, AESKey128, DFS);
      end;
      { --  192 位密匙最大长度为 24 个字符 -- }
      if KeyBit = kb192 then
      begin
        FillChar(AESKey192, SizeOf(AESKey192), 0);
        Move(PChar(Key)^, AESKey192, Min(SizeOf(AESKey192), Length(Key)));
        DecryptAESStreamECB(SFS, SFS.Size - SFS.Position, AESKey192, DFS);
      end;
      { --  256 位密匙最大长度为 32 个字符 -- }
      if KeyBit = kb256 then
      begin
        FillChar(AESKey256, SizeOf(AESKey256), 0);
        Move(PChar(Key)^, AESKey256, Min(SizeOf(AESKey256), Length(Key)));
        DecryptAESStreamECB(SFS, SFS.Size - SFS.Position, AESKey256, DFS);
      end;
      DFS.Size := Size;
    finally
      DFS.Free;
    end;
  finally
    SFS.Free;
  end;
end;

end.
