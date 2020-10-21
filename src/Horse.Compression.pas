unit Horse.Compression;


interface

uses Horse, System.Classes, System.ZLib, System.SysUtils, Web.HTTPApp, System.JSON;

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
type
  TCompressionType = (ctDeflate, ctGZIP);

const
  COMPRESSION_TYPE_AS_STRING: array [TCompressionType] of string = ('deflate', 'gzip');
  COMPRESSION_ZLIB_WINDOW_BITS: array [TCompressionType] of Integer = (-15, 31);

var
  LMemoryStream: TMemoryStream;
  LAcceptEncoding: string;
  LZStream: TZCompressionStream;
  LCompressionType: TCompressionType;
  LWebResponse: TWebResponse;
  LContent: string;
begin
  Next;

  LAcceptEncoding := Req.Headers['accept-encoding'];
  if LAcceptEncoding.Trim.IsEmpty then
    Exit;

  LContent := THorseHackResponse(Res).GetWebResponse.Content;
  if LContent.Trim.IsEmpty then
    Exit;

  LWebResponse := THorseHackResponse(Res).GetWebResponse;
  LWebResponse.ContentStream := TStringStream.Create(LContent);

  if LWebResponse.ContentStream.Size <= CompressionThreshold then
    Exit;

  if (Pos(COMPRESSION_TYPE_AS_STRING[TCompressionType.ctGZIP], LAcceptEncoding.Trim.ToLower) > 0) then
    LCompressionType := TCompressionType.ctGZIP
  else
    LCompressionType := TCompressionType.ctDeflate;

  LMemoryStream := TMemoryStream.Create;
  try
    LWebResponse.ContentStream.Position := 0;

    LZStream := TZCompressionStream.Create(LMemoryStream, TZCompressionLevel.ZcMax, COMPRESSION_ZLIB_WINDOW_BITS[LCompressionType]);
    try
      LZStream.CopyFrom(LWebResponse.ContentStream, 0);
    finally
      FreeAndNil(LZStream);
    end;

    LMemoryStream.Position := 0;

    LWebResponse.Content := EmptyStr;
    LWebResponse.ContentStream.Size := 0;
    LWebResponse.ContentStream.CopyFrom(LMemoryStream, 0);
    LWebResponse.ContentEncoding := COMPRESSION_TYPE_AS_STRING[LCompressionType];
  finally
    FreeAndNil(LMemoryStream);
  end;
end;

end.