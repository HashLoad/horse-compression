# horse-compression
<b>horse-compression</b> is a official middleware for compressing content in APIs developed with the <a href="https://github.com/HashLoad/horse">Horse</a> framework.
<br>We created a channel on Telegram for questions and support:<br><br>
<a href="https://t.me/hashload">
  <img src="https://img.shields.io/badge/telegram-join%20channel-7289DA?style=flat-square">
</a>

## ⚙️ Installation
Installation is done using the [`boss install`](https://github.com/HashLoad/boss) command:
``` sh
boss install horse-compression
```
If you choose to install manually, simply add the following folders to your project, in *Project > Options > Resource Compiler > Directories and Conditionals > Include file search path*
```
../horse-compression/src
```

## ✔️ Compatibility
This middleware is compatible with projects developed in:
- [X] Delphi
- [X] Lazarus

## ☑️ Compression types
Currently, the middleware is prepared to compress the data using DEFLATE and GZIP.
| Type | Delphi | Lazarus |
| -------- | -------------------- | --------------------------- |
|  DEFLATE | &nbsp;&nbsp;&nbsp;✔️ | &nbsp;&nbsp;&nbsp;&nbsp;✔️ |
|  GZIP    | &nbsp;&nbsp;&nbsp;✔️ | &nbsp;&nbsp;&nbsp;&nbsp;❌ |

## ⚡️ Quickstart Delphi
```delphi
uses
  Horse,
  Horse.Jhonson,
  Horse.Compression, // It's necessary to use the unit
  System.JSON;

begin
  THorse
    .Use(Compression()) // Must come before Jhonson middleware
    .Use(Jhonson);

  // You can set compression threshold:
  // THorse.Use(Compression(1024));

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
end;
```

## ⚡️ Quickstart Lazarus
```delphi
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

begin
  THorse
    .Use(Compression()) // Must come before Jhonson middleware
    .Use(Jhonson);

  // You can set compression threshold:
  // THorse.Use(Compression(1024));

  THorse.Get('/ping', GetPing);

  THorse.Listen(9000);
end.
```

## 🚀 Statistics 

Using middleware, the response was approximately 67 turn smaller. Data were collected using the project available within the [samples (delphi)](https://github.com/HashLoad/horse-compression/tree/master/samples/delphi) folder. To default, responses less than or equal to 1024 bytes will not be compressed.

Property    | Without | With
:---------: | ------: | ------:
Time(ms)    |     108 | 126
Size(bytes) |  15.770 | 236

## ⚠️ License
`horse-compression` is free and open-source middleware licensed under the [MIT License](https://github.com/HashLoad/horse-compression/blob/master/LICENSE). 
