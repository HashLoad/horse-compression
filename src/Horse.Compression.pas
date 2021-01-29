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
  ACCEPT_ENCODING = 'accept-encoding';
var
  LMemoryStream: TMemoryStream;
  LAcceptEncoding: string;
  LZStream: {$IF DEFINED(FPC)}TCompressionStream{$ELSE}TZCompressionStream{$ENDIF};
  LResponseCompressionType: THorseCompressionType;
  LContent: TObject;
begin
  Next;
  LContent := Res.Content;
  if (not Assigned(LContent)) or (not LContent.InheritsFrom({$IF DEFINED(FPC)}TJsonData{$ELSE}TJSONValue{$ENDIF})) then
    Exit;
  LAcceptEncoding := Req.Headers[ACCEPT_ENCODING];
  if LAcceptEncoding.Trim.IsEmpty then
    Exit;
  LAcceptEncoding := LAcceptEncoding.ToLower;
  if Pos(THorseCompressionType.DEFLATE.ToString, LAcceptEncoding) > 0 then
    LResponseCompressionType := THorseCompressionType.DEFLATE
  {$IF NOT DEFINED(FPC)}
  else if Pos(THorseCompressionType.GZIP.ToString, LAcceptEncoding) > 0 then
    LResponseCompressionType := THorseCompressionType.GZIP
  {$ENDIF}
  else
    Exit;
  Res.RawWebResponse.ContentStream := TStringStream.Create({$IF DEFINED(FPC)}TJsonData(LContent).AsJSON{$ELSE}TJSONValue(LContent).ToJSON{$ENDIF});
  if Res.RawWebResponse.ContentStream.Size <= CompressionThreshold then
    Exit;
  LMemoryStream := TMemoryStream.Create;
  try
    Res.RawWebResponse.ContentStream.Position := 0;
    {$IF DEFINED(FPC)}
    LZStream := TCompressionStream.Create(Tcompressionlevel.clmax, LMemoryStream,  LResponseCompressionType.WindowsBits = -15);
    {$ELSE}
    LZStream := TZCompressionStream.Create(LMemoryStream, TZCompressionLevel.zcMax, LResponseCompressionType.WindowsBits);
    {$ENDIF}
    try
      Res.RawWebResponse.ContentStream.Position := 0;
      LZStream.CopyFrom(Res.RawWebResponse.ContentStream, 0);
    finally
      LZStream.Free;
    end;
    LMemoryStream.Position := 0;
    Res.RawWebResponse.ContentStream.Size := 0;
    Res.RawWebResponse.ContentStream.CopyFrom(LMemoryStream, 0);
    {$IF DEFINED(FPC)}
    Res.RawWebResponse.ContentLength :=  LMemoryStream.Size;
    {$ELSE}
    Res.RawWebResponse.Content := EmptyStr;
    {$ENDIF}
    Res.RawWebResponse.ContentEncoding := LResponseCompressionType.ToString;
  finally
    LMemoryStream.Free;
  end;
end;

end.
