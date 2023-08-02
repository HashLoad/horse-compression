unit Horse.Compression;

{$IF DEFINED(FPC)}
  {$MODE DELPHI}{$H+}
{$ENDIF}

interface

uses
{$IF DEFINED(FPC)}
  SysUtils, Classes, zstream, HTTPDefs, fpjson,
{$ELSE}
  System.Classes, System.ZLib, System.SysUtils, Web.HTTPApp, System.JSON,
{$ENDIF}
  Horse.Compression.Types, Horse;

const
  COMPRESSION_THRESHOLD = 1024;

procedure Middleware(Req: THorseRequest; Res: THorseResponse; Next: {$IF DEFINED(FPC)}TNextProc{$ELSE}TProc{$ENDIF});
function Compression(const ACompressionThreshold: Integer = COMPRESSION_THRESHOLD): THorseCallback;

implementation

var
  CompressionThreshold: Integer;

function Compression(const ACompressionThreshold: Integer = COMPRESSION_THRESHOLD): THorseCallback;
begin
  CompressionThreshold := ACompressionThreshold;
  Result := {$IF DEFINED(FPC)}@Middleware{$ELSE}Middleware{$ENDIF};
end;

procedure Middleware(Req: THorseRequest; Res: THorseResponse; Next: {$IF DEFINED(FPC)}TNextProc{$ELSE}TProc{$ENDIF});
const
  ACCEPT_ENCODING = 'Accept-Encoding';
var
  LMemoryStream: TMemoryStream;
  LAcceptEncoding: string;
  LZStream: {$IF DEFINED(FPC)}TCompressionStream{$ELSE}TZCompressionStream{$ENDIF};
  LResponseCompressionType: THorseCompressionType;
  LStringStream: TStringStream;
begin
  Next;
  if Trim(Res.RawWebResponse.Content) = EmptyStr then
    if (Res.Content = nil) or (not Res.Content.InheritsFrom({$IF DEFINED(FPC)}TJsonData{$ELSE}TJSONValue{$ENDIF})) then
      Exit;
  if Trim(Req.Headers[ACCEPT_ENCODING]) = EmptyStr then
    Exit;
  LAcceptEncoding := Req.Headers[ACCEPT_ENCODING].ToLower;
  if Pos(THorseCompressionType.DEFLATE.ToString, LAcceptEncoding) > 0 then
    LResponseCompressionType := THorseCompressionType.DEFLATE
  {$IF NOT DEFINED(FPC)}
  else if Pos(THorseCompressionType.GZIP.ToString, LAcceptEncoding) > 0 then
    LResponseCompressionType := THorseCompressionType.GZIP
  {$ENDIF}
  else
    Exit;
  LStringStream := nil;
  try
    if Trim(Res.RawWebResponse.Content) = EmptyStr then
      LStringStream := TStringStream.Create({$IF DEFINED(FPC)}TJsonData(Res.Content).AsJSON{$ELSE}TJSONValue(Res.Content).ToJSON{$ENDIF})
    else
      LStringStream := TStringStream.Create(Res.RawWebResponse.Content {$IF NOT DEFINED(FPC)}, TEncoding.UTF8{$ENDIF});
    if LStringStream.Size <= CompressionThreshold then
      Exit;
    LMemoryStream := TMemoryStream.Create;
    {$IF DEFINED(FPC)}
    LZStream := TCompressionStream.Create(Tcompressionlevel.clmax, LMemoryStream, False);
    {$ELSE}
    LZStream := TZCompressionStream.Create(LMemoryStream, TZCompressionLevel.zcMax, LResponseCompressionType.WindowsBits);
    {$ENDIF}
    try
      LStringStream.Position := 0;
      LZStream.CopyFrom(LStringStream, 0);
    finally
      LZStream.Free;
    end;
    LMemoryStream.Position := 0;
    Res.RawWebResponse.ContentStream := LMemoryStream;
    {$IF DEFINED(FPC)}
    Res.RawWebResponse.ContentLength := LMemoryStream.Size;
    {$ELSE}
    Res.RawWebResponse.Content := EmptyStr;
    {$ENDIF}
    Res.RawWebResponse.ContentEncoding := LResponseCompressionType.ToString;
  finally
    LStringStream.Free;
  end;
end;

end.
