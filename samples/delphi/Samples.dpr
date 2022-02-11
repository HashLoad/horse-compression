program Samples;

{$APPTYPE CONSOLE}
{$R *.res}

uses
  Horse,
  Horse.Compression, // It's necessary to use the unit
  System.JSON;

begin
  THorse
    .Use(Compression()); // Must come before Jhonson middleware

  // You can set compression threshold:
  // THorse.Use(Compression(1024));

  THorse.Get('/ping',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      I: Integer;
      LPong: TJSONArray;
    begin
      LPong := TJSONArray.Create;
      try
        for I := 0 to 1000 do
          LPong.Add(TJSONObject.Create(TJSONPair.Create('ping', 'pong')));
        Res.Send(LPong.ToJSON);
      finally
        LPong.Free;
      end;
    end);

  THorse.Listen;
end.
