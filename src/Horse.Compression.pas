unit Horse.Compression;

interface

uses Horse;

procedure Compression(Req: THorseRequest; Res: THorseResponse; Next: TProc);

implementation

uses System.Classes, System.ZLib, Horse.Compression.Types, System.SysUtils, Web.HTTPApp, System.JSON;

procedure Compression(Req: THorseRequest; Res: THorseResponse; Next: TProc);
const
  COMPRESSION_THRESHOLD = 1024;
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
  LWebResponse := THorseHackResponse(Res).GetWebResponse;
  if (not Assigned(LContent)) or (not LContent.InheritsFrom(TJSONValue)) then
    Exit;
  if not Req.Headers.TryGetValue(ACCEPT_ENCODING, LAcceptEncoding) then
    Exit;
  if Pos(THorseCompressionType.GZIP.ToString, LAcceptEncoding.ToLower) > 0 then
    LResponseCompressionType := THorseCompressionType.GZIP
  else if Pos(THorseCompressionType.DEFLATE.ToString, LAcceptEncoding.ToLower) > 0 then
    LResponseCompressionType := THorseCompressionType.DEFLATE
  else
    Exit;
  LWebResponse.ContentStream := TStringStream.Create(TJSONValue(LContent).ToJSON);
  if LWebResponse.ContentStream.Size <= COMPRESSION_THRESHOLD then
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
