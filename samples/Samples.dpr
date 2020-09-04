program Samples;

{$APPTYPE CONSOLE}
{$R *.res}

uses Horse, Horse.Jhonson, Horse.Compression, System.JSON;

begin
  THorse
    .Use(Compression()) // Must come before Jhonson middleware
    .Use(Jhonson);

  THorse.Get('/ping',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      I: Integer;
      LPong: TJSONArray;
    begin
      LPong := TJSONArray.Create;
      for I := 0 to 1000 do
        LPong.Add(TJSONObject.Create(TJSONPair.Create('ping', 'pong')));
      Res.Send(LPong);
    end);

  THorse.Listen(9000);
end.
