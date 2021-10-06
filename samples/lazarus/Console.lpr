program Console;

{$MODE DELPHI}{$H+}

uses
  {$IFDEF UNIX}{$IFDEF UseCThreads}
  cthreads,
  {$ENDIF}{$ENDIF}
  Horse,
  Horse.Jhonson,
  Horse.Compression, // It's necessary to use the unit
  fpjson,
  SysUtils;

procedure GetPing(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  I: Integer;
  LPong: TJSONArray;
  LJson: TJSONObject;
begin
  LPong := TJSONArray.Create;
  for I := 0 to 1000 do
  begin
    LJson := TJSONObject.Create;
    LJson.Add('ping', 'pong');
    LPong.Add(LJson);
  end;
  Res.Send<TJSONArray>(LPong);
end;

procedure OnListen(Horse: THorse);
begin
  Writeln(Format('Server is runing on %s:%d', [Horse.Host, Horse.Port]));
end;

begin
  THorse
    .Use(Compression()) // Must come before Jhonson middleware
    .Use(Jhonson);

  // You can set compression threshold:
  // THorse.Use(Compression(1024));

  THorse.Get('/ping', GetPing);

  THorse.Listen(9000, OnListen);
end.
