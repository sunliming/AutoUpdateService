unit uStatusEcho;

interface

procedure StatusEchoInit;
procedure StatusEchoFree;

implementation

uses Windows, SysUtils, DateUtils, Classes, IdUDPServer, IDSocketHandle;

type
  TUDPServerOwner = class
    constructor Create;
    destructor Destroy; override;
  private
    FInitUDPOK: boolean;
    FUDPServer: TIdUDPServer;
    procedure BuildEchoInfo(ABuf: PByteArray; ABufLen: integer);
    procedure OnUDPRead(Sender: TObject; AData: TStream; ABinding: TIdSocketHandle);
  end;

var
  usoMain: TUDPServerOwner;
  
procedure StatusEchoInit;
begin
  usoMain := TUDPServerOwner.Create;
end;

procedure StatusEchoFree;
begin
  FreeAndNil(usoMain);
end;

{ TUDPServerOwner }

procedure TUDPServerOwner.BuildEchoInfo(ABuf: PByteArray; ABufLen: integer);
begin
  ZeroMemory(ABuf, ABufLen);
end;

constructor TUDPServerOwner.Create;
begin
  FInitUDPOK := false;

  try
    FUDPServer := TIdUDPServer.Create(nil);
    FUDPServer.DefaultPort := 12345;
    FUDPServer.OnUDPRead := OnUDPRead;
    FUDPServer.Active := true;
    FInitUDPOK := true;
  except
  end;
end;

destructor TUDPServerOwner.Destroy;
begin
  try
    if Assigned(FUDPServer) then
    begin
      FUDPServer.Active := false;
      FUDPServer.Free;
    end;
  except
  end;
  
  inherited;
end;

procedure TUDPServerOwner.OnUDPRead(Sender: TObject; AData: TStream;
  ABinding: TIdSocketHandle);
var
  buf: array[0..127] of byte;
begin
  BuildEchoInfo(@buf[0], SizeOf(buf));
  ABinding.SendTo(ABinding.PeerIp, ABinding.PeerPort, buf[0], SizeOf(buf));
end;

end.
