unit Horse.Compression;

interface

uses Horse;

procedure Compression(Req: THorseRequest; Res: THorseResponse; Next: TProc);

implementation

uses System.Classes, System.ZLib, Horse.Compression.Types, System.SysUtils, Web.HTTPApp;

procedure Compression(Req: THorseRequest; Res: THorseResponse; Next: TProc);
const
  COMPRESSION_THRESHOLD = 1024;
  ACCEPT_ENCODING = 'Accept-Encoding';
var
  LMemoryStream: TMemoryStream;
  LAcceptEncoding: string;
  LZStream: TZCompressionStream;
  LResponseCompressionType: THorseCompressionType;
  LWebResponse: TWebResponse;
begin
  LWebResponse := THorseHackResponse(Res).GetWebResponse;
  if (not Assigned(LWebResponse.ContentStream)) or (LWebResponse.ContentStream is TFileStream) or
    (LWebResponse.ContentStream.Size <= COMPRESSION_THRESHOLD) then
    Exit;
  if not Req.Headers.TryGetValue(ACCEPT_ENCODING, LAcceptEncoding) then
    Exit;
  if Pos(THorseCompressionType.GZIP.ToString, LAcceptEncoding.ToLower) > 0 then
    LResponseCompressionType := THorseCompressionType.GZIP
  else if Pos(THorseCompressionType.DEFLATE.ToString, LAcceptEncoding.ToLower) > 0 then
    LResponseCompressionType := THorseCompressionType.DEFLATE
  else
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
    {$IF Defined(SeattleOrBetter)}
      LWebResponse.ContentEncoding := LResponseCompressionType.ToString;
    {$ELSE}
      LWebResponse.ContentEncoding := AnsiString(LResponseCompressionType.ToString);
    {$ENDIF}
  finally
    LMemoryStream.Free;
  end;
end;

end.
