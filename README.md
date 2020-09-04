# horse-compression

Middleware for compression in HORSE

Sample Horse server using compression:

```delphi
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
```

## Statistics 

Using middleware, the response was approximately 67 turn smaller. Data were collected using the project available within the [samples](https://github.com/viniciussanchez/horse-compression/tree/master/samples) folder. Responses less than or equal to 1024 bytes will not be compressed.

Property    | Without | With
:---------: | ------: | ------:
Time(ms)    |     108 | 126
Size(bytes) |  15.770 | 236
