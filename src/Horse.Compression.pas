unit Horse.Compression;

{$IF DEFINED(FPC)}
  {$MODE DELPHI}{$H+}
{$ENDIF}

interface

uses
{$IF DEFINED(FPC)}
  SysUtils, Classes, zstream, crc, HTTPDefs, fpjson,
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
  Result := Middleware;
end;

procedure Middleware(Req: THorseRequest; Res: THorseResponse; Next: {$IF DEFINED(FPC)}TNextProc{$ELSE}TProc{$ENDIF});
const
  ACCEPT_ENCODING = 'Accept-Encoding';
  {$IF DEFINED(FPC)}
  // zstream has no gzip mode: gzip is this header + raw deflate + CRC32 and size (RFC 1952)
  GZIP_HEADER: array[0..9] of Byte = ($1F, $8B, $08, $00, 0, 0, 0, 0, $02, $FF);
  {$ENDIF}
var
  LMemoryStream: TMemoryStream;
  LAcceptEncoding: string;
  LZStream: {$IF DEFINED(FPC)}TCompressionStream{$ELSE}TZCompressionStream{$ENDIF};
  LResponseCompressionType: THorseCompressionType;
  LStringStream: TStringStream;
begin
  Next;
  // Horse 3.3+ on FPC sends Res.Send(string) as RawWebResponse.ContentStream, not Content
  if (Trim(Res.RawWebResponse.Content) = EmptyStr) {$IF DEFINED(FPC)}and (Res.RawWebResponse.ContentStream = nil){$ENDIF} then
    if (Res.Content = nil) or (not Res.Content.InheritsFrom({$IF DEFINED(FPC)}TJsonData{$ELSE}TJSONValue{$ENDIF})) then
      Exit;
  if Trim(Req.Headers[ACCEPT_ENCODING]) = EmptyStr then
    Exit;
  LAcceptEncoding := Req.Headers[ACCEPT_ENCODING].ToLower;
  if Pos(THorseCompressionType.DEFLATE.ToString, LAcceptEncoding) > 0 then
    LResponseCompressionType := THorseCompressionType.DEFLATE
  else if Pos(THorseCompressionType.GZIP.ToString, LAcceptEncoding) > 0 then
    LResponseCompressionType := THorseCompressionType.GZIP
  else
    Exit;
  LStringStream := nil;
  try
    {$IF DEFINED(FPC)}
    if (Trim(Res.RawWebResponse.Content) = EmptyStr) and (Res.RawWebResponse.ContentStream <> nil) then
    begin
      LStringStream := TStringStream.Create('');
      LStringStream.CopyFrom(Res.RawWebResponse.ContentStream, 0);
    end
    else
    {$ENDIF}
    if Trim(Res.RawWebResponse.Content) = EmptyStr then
      LStringStream := TStringStream.Create({$IF DEFINED(FPC)}TJsonData(Res.Content).AsJSON{$ELSE}TJSONValue(Res.Content).ToJSON{$ENDIF})
    else
      LStringStream := TStringStream.Create(Res.RawWebResponse.Content {$IF NOT DEFINED(FPC)}, TEncoding.UTF8{$ENDIF});
    if LStringStream.Size <= CompressionThreshold then
      Exit;
    LMemoryStream := TMemoryStream.Create;
    {$IF DEFINED(FPC)}
    if LResponseCompressionType = THorseCompressionType.GZIP then
      LMemoryStream.WriteBuffer(GZIP_HEADER, SizeOf(GZIP_HEADER));
    LZStream := TCompressionStream.Create(Tcompressionlevel.clmax, LMemoryStream,
      LResponseCompressionType = THorseCompressionType.GZIP);
    {$ELSE}
    LZStream := TZCompressionStream.Create(LMemoryStream, TZCompressionLevel.zcMax, LResponseCompressionType.WindowsBits);
    {$ENDIF}
    try
      LStringStream.Position := 0;
      LZStream.CopyFrom(LStringStream, 0);
    finally
      LZStream.Free;
    end;
    {$IF DEFINED(FPC)}
    if LResponseCompressionType = THorseCompressionType.GZIP then
    begin
      LMemoryStream.WriteDWord(NtoLE(crc32(crc32(0, nil, 0), PByte(LStringStream.Memory), LStringStream.Size)));
      LMemoryStream.WriteDWord(NtoLE(LongWord(LStringStream.Size)));
    end;
    {$ENDIF}
    LMemoryStream.Position := 0;
    Res.RawWebResponse.ContentStream := LMemoryStream;
    {$IF DEFINED(FPC)}
    Res.RawWebResponse.FreeContentStream := True;
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
