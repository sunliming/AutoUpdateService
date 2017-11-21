unit uSocket;

interface

procedure InitTCPSocket;
procedure FreeTCPSocket;

implementation

uses ScktComp;

type
  TTCPSocket = class
    constructor Create;
    destructor Destroy; override;
  private
    FServerSocket: TServerSocket;
    procedure OnSocketError(Sender: TObject; Socket: TCustomWinSocket; ErrorEvent: TErrorEvent; var ErrorCode: Integer);
  end;

var
  MyServerSocket: TTCPSocket;
  
procedure InitTCPSocket;
begin
  MyServerSocket := TTCPSocket.Create;
end;

procedure FreeTCPSocket;
begin
  MyServerSocket.Free;
end;

{ TTCPSocket }

constructor TTCPSocket.Create;
begin
  FServerSocket := TServerSocket.Create(nil);
  FServerSocket.Port := 10777;
  FServerSocket.ServerType := stNonBlocking;
  FServerSocket.OnClientError := OnSocketError;
  FServerSocket.Active := true;
end;

destructor TTCPSocket.Destroy;
begin
  FServerSocket.Active := false;
  FServerSocket.Free;
  inherited;
end;

procedure TTCPSocket.OnSocketError(Sender: TObject;
  Socket: TCustomWinSocket; ErrorEvent: TErrorEvent;
  var ErrorCode: Integer);
begin
  ErrorCode := 0;
end;

end.
