unit IDEA;

interface

function IDEA_Crypt(const AData: pchar;
                    const ALen: integer;
                    const key: array of WORD;
                    const AMode: byte): boolean;

implementation

uses windows;

var
  encrykey: array [0..55] of Word;

function mult(const a, b: Word): Word;
var
  p: Longword;
  q, r: Word;
begin
  if a<>0 then
  begin
    if b<>0 then
    begin
      p := a * b;
      q := p shr 16;
      r := p - (q shl 16);
      if r < q then result := r-q+1 else result := r-q;
    end
    else result := 1 - a;
  end
  else result := 1 - b;
end;

function inv(p: Word): Word;
var
  q, y, t0, t1: Word;
begin
  if p<=1 then
  begin
    result := p;
    exit;
  end;

  t1 := $10001 div p;
  y := $10001 mod p;
  if y=1 then
  begin
    result := 1-t1;
    exit;
  end;

  t0 := 1;
  repeat
    q := p div y;
    p := p mod y;
    t0 := t0 + q*t1;
    if p=1 then
    begin
      result := t0;
      exit;
    end;
    q := y div p;
    y := y mod p;
    t1 := t1 + q*t0;
  until y = 1;
  result := 1-t1;
end;

////////////////////////////////////////////////////////////////////////////////
//  生成加密密钥
////////////////////////////////////////////////////////////////////////////////
procedure esubkey(const pa1: array of Word);
var
  i, j: Byte;
begin
  for i:=0 to 7 do
    encrykey[i] := pa1[i];
  for j:=0 to 5 do
  begin
    for i:=1 to 6 do
      encrykey[i+7+8*j] := encrykey[i+8*j] shl 9 or encrykey[i+1+8*j] shr 7;
    //encrykey[i+7+8*j] := encrykey[i+8*j] shl 9 or encrykey[i-7+8*j] shr 7;
    //encrykey[i+8+8*j] := encrykey[i-7+8*j] shl 9 or encrykey[i-6+8*j] shr 7;
    encrykey[7+7+8*j] := encrykey[7+8*j] shl 9 or encrykey[7-7+8*j] shr 7;
    encrykey[7+8+8*j] := encrykey[7-7+8*j] shl 9 or encrykey[7-6+8*j] shr 7;
  end;
end;

////////////////////////////////////////////////////////////////////////////////
//  生成解密密钥
////////////////////////////////////////////////////////////////////////////////
procedure dsubkey;
var
  i: Byte;
  buffer: array [0..51] of Word;
begin
  for i:=0 to 51 do
    if i mod 3 = 0 then
    begin
      if i mod 6 = 0 then
        buffer[i] := inv(encrykey[48-i])
      else
        buffer[i] := inv(encrykey[54-i]);
    end
    else if (i mod 6 = 1) or (i mod 6 = 2) then
    begin
      if i in [1,2,49,50] then
      begin
        if i mod 2 = 0 then
          buffer[i] := -encrykey[52-i]
        else
          buffer[i] := -encrykey[50-i];
      end
      else
        buffer[i] := -encrykey[51-i];
    end
    else begin
      if i mod 6 = 4 then
        buffer[i] := encrykey[50-i]
      else
        buffer[i] := encrykey[52-i];
    end;

  for i:=0 to 51 do
    encrykey[i] := buffer[i];
end;

////////////////////////////////////////////////////////////////////////////////
//  加密
////////////////////////////////////////////////////////////////////////////////
procedure encrypt(var x: array of Word; const count: integer);
var
  i: integer;
  s: array [0..3] of Word;
  p1, p2: Word;
begin
  for i:=0 to count-1 do s[i] := x[i];
  for i:=0 to 7 do
  begin
    s[0] := mult(s[0], encrykey[6*i]);
    s[1] := s[1] + encrykey[6*i+1];
    p1 := s[1];
    s[2] := s[2] + encrykey[6*i+2];
    p2 := s[2];
    s[3] := mult(s[3], encrykey[6*i+3]);
    s[2] := s[2] xor s[0];
    s[1] := s[1] xor s[3];
    s[2] := mult(s[2], encrykey[6*i+4]);
    s[1] := s[1] + s[2];
    s[1] := mult(s[1], encrykey[6*i+5]);
    s[2] := s[2] + s[1];
    s[3] := s[3] xor s[2];
    s[0] := s[0] xor s[1];
    p2 := p2 xor s[1];
    p1 := p1 xor s[2];
    s[1] := p2;
    s[2] := p1;
  end;

  x[0] := mult(s[0], encrykey[48]);
  x[1] := s[2] + encrykey[49];
  x[2] := s[1] + encrykey[50];
  x[3] := mult(s[3], encrykey[51]);
end;

function ECB(const x: pchar; const ALen: integer): boolean;
var
  p: pchar;
  s: array [0..3] of Word;
  i: Integer;
begin
  result := false;

  if ALen mod 8 <> 0 then exit;

  p := x;
  for i:=0 to ALen div 8 - 1 do
  begin
    CopyMemory(@s[0], p+i*8, 8);
    encrypt(s, 4);
    CopyMemory(p+i*8, @s[0], 8);
  end;

  result := true;
end;

function IDEA_Crypt(const AData: pchar;
                    const ALen: integer;
                    const key: array of WORD;
                    const AMode: byte): boolean;
begin
  esubkey(key);
  if AMode = 1 then dsubkey; //解密
  result := ECB(AData, ALen);
end;

end.
