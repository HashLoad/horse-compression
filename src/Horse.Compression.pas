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
  LWebResponse: {$IF DEFINED(FPC)}TResponse{$ELSE}TWebResponse{$ENDIF};
  LContent: TObject;
begin
  Next;
  LContent := THorseHackResponse(Res).GetContent;
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
  LWebResponse := THorseHackResponse(Res).GetWebResponse;
  LWebResponse.ContentStream := TStringStream.Create({$IF DEFINED(FPC)}TJsonData(LContent).AsJSON{$ELSE}TJSONValue(LContent).ToJSON{$ENDIF});
  if LWebResponse.ContentStream.Size <= CompressionThreshold then
    Exit;
  LMemoryStream := TMemoryStream.Create;
  try
    LWebResponse.ContentStream.Position := 0;
    {$IF DEFINED(FPC)}
    LZStream := TCompressionStream.Create(Tcompressionlevel.clmax, LMemoryStream,  LResponseCompressionType.WindowsBits = -15);
    {$ELSE}
    LZStream := TZCompressionStream.Create(LMemoryStream, TZCompressionLevel.zcMax, LResponseCompressionType.WindowsBits);
    {$ENDIF}
    try
      LWebResponse.ContentStream.Position := 0;
      LZStream.CopyFrom(LWebResponse.ContentStream, 0);
    finally
      LZStream.Free;
    end;
    LMemoryStream.Position := 0;
    LWebResponse.ContentStream.Size := 0;
    LWebResponse.ContentStream.CopyFrom(LMemoryStream, 0);
    {$IF DEFINED(FPC)}
    LWebResponse.ContentLength :=  LMemoryStream.Size;
    {$ELSE}
    LWebResponse.Content := EmptyStr;
    {$ENDIF}
    LWebResponse.ContentEncoding := LResponseCompressionType.ToString;
  finally
    LMemoryStream.Free;
  end;
end;

end.
