unit Horse.Compression;

interface

uses Horse, System.Classes, System.ZLib, Horse.Compression.Types, System.SysUtils, Web.HTTPApp, System.JSON;

const
  COMPRESSION_THRESHOLD = 1024;

procedure Middleware(Req: THorseRequest; Res: THorseResponse; Next: TProc);
function Compression(const ACompressionThreshold: Integer = COMPRESSION_THRESHOLD): THorseCallback;

implementation

var
  CompressionThreshold: Integer;

function Compression(const ACompressionThreshold: Integer = COMPRESSION_THRESHOLD): THorseCallback;
begin
  CompressionThreshold := ACompressionThreshold;
  Result := Middleware;
end;

procedure Middleware(Req: THorseRequest; Res: THorseResponse; Next: TProc);
const
  ACCEPT_ENCODING = 'accept-encoding';
var
  LMemoryStream: TMemoryStream;
  LAcceptEncoding: string;
  LZStream: TZCompressionStream;
  LResponseCompressionType: THorseCompressionType;
  LWebResponse: TWebResponse;
  LContent: TObject;
begin
  Next;
  LContent := THorseHackResponse(Res).GetContent;
  if (not Assigned(LContent)) or (not LContent.InheritsFrom(TJSONValue)) then
    Exit;
  LAcceptEncoding := Req.Headers[ACCEPT_ENCODING];
  if LAcceptEncoding.Trim.IsEmpty then
    Exit;
  LAcceptEncoding := LAcceptEncoding.ToLower;
  if Pos(THorseCompressionType.GZIP.ToString, LAcceptEncoding) > 0 then
    LResponseCompressionType := THorseCompressionType.GZIP
  else if Pos(THorseCompressionType.DEFLATE.ToString, LAcceptEncoding) > 0 then
    LResponseCompressionType := THorseCompressionType.DEFLATE
  else
    Exit;
  LWebResponse := THorseHackResponse(Res).GetWebResponse;
  LWebResponse.ContentStream := TStringStream.Create(TJSONValue(LContent).ToJSON);
  if LWebResponse.ContentStream.Size <= CompressionThreshold then
    Exit;
  LMemoryStream := TMemoryStream.Create;
  try
    LWebResponse.ContentStream.Position := 0;
    LZStream := TZCompressionStream.Create(LMemoryStream, TZCompressionLevel.zcMax, LResponseCompressionType.WindowsBits);
    try
      LZStream.CopyFrom(LWebResponse.ContentStream, 0);
    finally
      LZStream.Free;
    end;
    LMemoryStream.Position := 0;
    LWebResponse.Content := EmptyStr;
    LWebResponse.ContentStream.Size := 0;
    LWebResponse.ContentStream.CopyFrom(LMemoryStream, 0);
    LWebResponse.ContentEncoding := LResponseCompressionType.ToString;
  finally
    LMemoryStream.Free;
  end;
end;

end.
