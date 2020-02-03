# horse-compression

Middleware for compression in HORSE

Sample Horse server using compression:

```delphi
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
      LPong: TJSONArray;
    begin
      LPong := TJSONArray.Create;
      for var I := 0 to 1000 do
        LPong.Add(TJSONObject.Create(TJSONPair.Create('ping', 'pong')));
      Res.Send(LPong);
    end);

  App.Start;
```

## Statistics 

Using middleware, the response was approximately 67 turn smaller. Data were collected using the project available within the [samples](https://github.com/viniciussanchez/horse-compression/tree/master/samples) folder. Responses less than or equal to 1024 bytes will not be compressed.

Property    | Without | With
:---------: | ------: | ------:
Time(ms)    |     108 | 126
Size(bytes) |  15.770 | 236
