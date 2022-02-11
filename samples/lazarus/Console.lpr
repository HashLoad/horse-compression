program Console;

{$MODE DELPHI}{$H+}

uses
  {$IFDEF UNIX}{$IFDEF UseCThreads}
  cthreads,
  {$ENDIF}{$ENDIF}
  Horse,
  Horse.Compression, // It's necessary to use the unit
  fpjson;

procedure GetPing(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  I: Integer;
  LPong: TJSONArray;
  LJson: TJSONObject;
begin
  LPong := TJSONArray.Create;
  try
    for I := 0 to 1000 do
    begin
      LJson := TJSONObject.Create;
      LJson.Add('ping', 'pong');
      LPong.Add(LJson);
    end;
    Res.Send(LPong.AsJSON);
  finally
    LPong.Free;
  end;
end;

begin
  THorse
    .Use(Compression()); // Must come before Jhonson middleware

  // You can set compression threshold:
  // THorse.Use(Compression(1024));

  THorse.Get('/ping', GetPing);

  THorse.Listen;
end.
