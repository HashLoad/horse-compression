unit Horse.Compression.Types;

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

{ THorseCompressionTypeHelper }

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
      Result := -15;
  else
    Result := 31;
  end;
end;

end.
