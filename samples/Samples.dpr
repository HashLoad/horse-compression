program Samples;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  Horse, Horse.Jhonson, Horse.Compression, System.JSON;

var
  App: THorse;

begin
  App := THorse.Create(9000);

  App.Use(Compression()); // Must come before Jhonson middleware
  App.Use(Jhonson);

  App.Get('ping',
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

  App.Start;
end.
