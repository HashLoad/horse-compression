unit Horse.Compression.Types;

{$IF DEFINED(FPC)}
  {$MODE DELPHI}{$H+}
{$ENDIF}

interface

type
{$SCOPEDENUMS ON}
  THorseCompressionType = (DEFLATE, GZIP);
{$SCOPEDENUMS OFF}

  THorseCompressionTypeHelper = record helper for THorseCompressionType
    function ToString: string;
    function WindowsBits: Integer;
  end;

implementation

function THorseCompressionTypeHelper.ToString: string;
begin
  case Self of
    THorseCompressionType.DEFLATE:
      Result := 'deflate';
    THorseCompressionType.GZIP:
      Result := 'gzip';
  end;
end;

function THorseCompressionTypeHelper.WindowsBits: Integer;
begin
  case Self of
    THorseCompressionType.DEFLATE:
      Result := 15;
  else
    Result := 31;
  end;
end;

end.
