{==============================================================================|
| Project : JSON/YAML Parser Tools for Object Pascal                           |
|==============================================================================|
| Content: YAML <--> JSON tooling                                              |
|==============================================================================|
| Copyright (c) 2024, Vahid Nasehi Oskouei                                     |
| All rights reserved.                                                         |
|                                                                              |
| License: MIT License                                                         |
|                                                                              |
| Remastered and rewritten version originally based on a work by:              |
|   Joao Costa, costate@sapo.pt                                                |
|   https://github.com/joao-m-costa/delphi-yaml-to-json                        |
| and reworked by:                                                             |
|   Lu Wey (TMS Core)                                                          |
|   https://github.com/LuWey/TextContainer                                     |
|                                                                              |
| Project download homepage:                                                   |
|   https://github.com/biot2/ParserTools                                       |
|                                                                              |
| History:                                                                     |
|   2024-10-05                                                                 |
|   - Support both Delphi and Free Pascal                                      |
|   - Added support for local tags                                             |
|   - Resolved issues with comments in the end of lines resolved               |
|   - Resolved issues with incorrent date/time format parsing resolved         |
|   - Added multiline binary support added                                     |
|   - JSON parser has beed replaced with Json Tools                            |
|   - Switched unicode support to utf-8 (AnsiString) for better compatibility  |
|     between platforms                                                        |
|                                                                              |
|==============================================================================|
| Requirements: Ararat Synapse (http://www.ararat.cz/synapse/)                 |
|==============================================================================}

unit Parser.YAML;

{$IFDEF FPC}
  {$MODE Delphi}
{$ENDIF}

interface

uses
  SysUtils, Classes, DateUtils, Parser.JSON, Generics.Collections;

type
  EYamlParsingException = class(Exception);

  TYamlUtils = class
  public
  type
    TYamlElement = record
      Key: AnsiString;
      Value: AnsiString;
      Indent: Integer;
      Literal: Boolean;
      Alias: AnsiString;
      Anchor: AnsiString;
      LineNumber: Integer;
      Tag: AnsiString;
      class procedure Initialize(out Dest: TYamlElement); static;
      class procedure Assign(var Dest: TYamlElement; const Src: TYamlElement); static;
      procedure Clear;
    end;
    TYamlElements = TList<TYamlElement>;

    TYamlTokenType = (tokenKey, tokenValue);
    TBlockModifier = (blockNone, blockFolded, blockLiteral); // None, >, |
    TChompModifier = (chompNone, chompClip, chompKeep);      // None, -, +
    TYamlIdentation = 2..8;
    TJsonIdentation = 0..8;
  private
    // Utilities section
    // -----------------
    // Escape YAML text to JSON
    class function InternalStringEscape(const AText: AnsiString): AnsiString;
    // Try convert a timestamp value to a datetime UTC
    class function InternalTryStrToDateTime(const AText: AnsiString; var ADate: TDateTime; AFormatSettings: TFormatSettings): Boolean;
    // YAML to JSON section
    // --------------------
    // Read next text YAML line from strings
    class function InternalYamlNextTextLine(AYAML: TStrings; var ARow, AIndent: Integer; AIgnoreBlanks: Boolean = True; AIgnoreComments: Boolean = True; AAutoTrim: Boolean = True): AnsiString;
    // Retrieve what next text will be
    class function InternalYamlNextText(AYAML: TStrings; var ARow, AIndent: Integer; AText: AnsiString; AIgnoreBlanks: Boolean = True; AIgnoreComments: Boolean = True; AAutoTrim: Boolean = True): AnsiString;
    // Read next token from source, with multiline support
    class function InternalYamlReadToken(AYAML: TStrings; var ARow, AIndent: Integer; var AText, ARemainer, AAlias, ATag: AnsiString; var ACollectionItem: Integer; var AIsLiteral: Boolean; AInArray: Boolean = False): TYamlTokenType;
    // Find element containing an anchor by anchor name
    class function InternalYamlFindAnchor(AElements: TYamlElements; AAnchorName: AnsiString): Integer;
    // Resolve (pre-process) aliases to anchor values
    class procedure InternalYamlResolveAliases(AElements: TYamlElements);
    // Merge (pre-process) aliases with anchor values
    class procedure InternalYamlResolveMerges(AElements: TYamlElements);
    // Process an inline array from source
    class procedure InternalYamlProcessArray(AYAML: TStrings; AElements: TYamlElements; var ARow, AIndent: Integer; var AText: AnsiString; AYesNoBool: Boolean; AAllowDuplicateKeys: Boolean);
    // Process a collection (array) from source
    class procedure InternalYamlProcessCollection(AYAML: TStrings; AElements: TYamlElements; var ARow, AIndent: Integer; var AText: AnsiString; AYesNoBool: Boolean; AAllowDuplicateKeys: Boolean);
    // Process element pairs (key: value) from source
    class procedure InternalYamlProcessElements(AYAML: TStrings; AElements: TYamlElements; var ARow, AIndent: Integer; var AText: AnsiString; AYesNoBool: Boolean; AAllowDuplicateKeys: Boolean);
    // Format a YAML value to JSON
    class function InternalYamlProcessJsonValue(AValue: AnsiString; ALiteral: Boolean; ATag: AnsiString; ALineNumber: Integer; AYesNoBool: Boolean): AnsiString;
    // Convert the prepared TYamlElements list to JSON
    class procedure InternalYamlToJson(AElements: TYamlElements; AJSON: TStrings; AIndentation: TJsonIdentation; AYesNoBool: Boolean);
    // Entry point to parse YAML to JSON
    class procedure InternalYamlParse(AYAML, AJSON: TStrings; AIndentation: TJsonIdentation; AYesNoBool: Boolean; AAllowDuplicateKeys: Boolean);
    // JSON to YAML section
    // --------------------
    // Process JSON object to YAML (a touple)
    class procedure InternalJsonObjToYaml(AJSON: TJsonNode; AOutStrings: TStrings; AIndentation: TYamlIdentation; var AIndent: Integer; AFromArray: Boolean = False; AYesNoBool: Boolean = False);
    // Process JSON array to YAML
    class procedure InternalJsonArrToYaml(AJSON: TJsonNode; AOutStrings: TStrings; AIndentation: TYamlIdentation; var AIndent: Integer; AFromArray: Boolean = False; AYesNoBool: Boolean = False);
    // Convert a value from JSON to YAML
    class function InternalJsonValueToYaml(AJSON: TJsonNode; AIndent: Integer = 0; AYesNoBool: Boolean = False): TArray<String>;
  public
    // JSON to YAML
    class function JsonToYaml(AJSON: AnsiString; AIndentation: TYamlIdentation = 2; AYesNoBool: Boolean = False): AnsiString; overload;
    class procedure JsonToYaml(AJSON: TStrings; AOutStrings: TStrings; AIndentation: TYamlIdentation = 2; AYesNoBool: Boolean = False); overload;
    class function JsonToYaml(AJSON: TJsonNode; AIndentation: TYamlIdentation = 2; AYesNoBool: Boolean = False): AnsiString; overload;
    class procedure JsonToYaml(AJSON: TJsonNode; AOutStrings: TStrings; AIndentation: TYamlIdentation = 2; AYesNoBool: Boolean = False); overload;
    // YAML to JSON
    class procedure YamlToJson(AYAML: TStrings; AOutStrings: TStrings; AIndentation: TJsonIdentation = 2; AYesNoBool: Boolean = True; AAllowDuplicateKeys: Boolean = True); overload;
    class function YamlToJson(AYAML: AnsiString; AIndentation: TJsonIdentation = 2; AYesNoBool: Boolean = True; AAllowDuplicateKeys: Boolean = True): AnsiString; overload;
    class function YamlToJson(AYAML: TStrings; AIndentation: TJsonIdentation = 2; AYesNoBool: Boolean = True; AAllowDuplicateKeys: Boolean = True): AnsiString; overload;
    class function YamlToJsonValue(AYAML: AnsiString; AIndentation: TJsonIdentation = 0; AYesNoBool: Boolean = True; AAllowDuplicateKeys: Boolean = True): TJsonNode; overload;
    class function YamlToJsonValue(AYAML: TStrings; AIndentation: TJsonIdentation = 0; AYesNoBool: Boolean = True; AAllowDuplicateKeys: Boolean = True): TJsonNode; overload;
    // JSON tools
    class function JsonMinify(AJSON: AnsiString): AnsiString; overload;
    class function JsonMinify(AJSON: TStrings): AnsiString; overload;
  end;

{##############################################################################}

implementation

uses synacode;

const
  EYamlCollectionItemError = 'Yaml invalid collection item at line %d';
  EYamlInvalidArrayError = 'Yaml invalid array at line %d';
  EYamlInvalidIndentError = 'Yaml invalid identation an line %d';
  EYamlAnchorAliasNameError = 'Yaml invalid alias/anchor name at line %d';
  EYamlAnchorDuplicateError = 'Yaml duplicated anchor name at line %d';
  EYamlCollectionBlockError = 'Yaml block modifiers can not be used for collection items at line %d';
  EYamlInvalidBlockError = 'Yaml invalid block modifier at line %d';
  EYamlUnclosedLiteralError = 'Yaml unclosed literal at line %d';
  EYamlKeyNameEmptyError = 'Yaml empty key name at line %d';
  EYamlKeyNameMultilineError = 'Yaml key names cannot be multiline at line %d';
  EYamlKeyNameAnchorAliasError = 'Yaml aliases/anchors cannot be used for keys at line %d';
  EYamlKeyNameInvalidCharError = 'Yaml invalid indicator "%s" for key al line %d';
  EYamlAnchorAliasValueError = 'Yaml aliases for anchors cannot contain values at line %d';
  EYamlUnconsumedContentError = 'Yaml unconsumed content at line %d';
  EYamlUnclosedArrayError = 'Yaml unclosed array at line %d';
  EYamlCollectionInArrayError = 'Yaml arrays cannot contain collection items at line %d';
  EYamlDoubleKeyError = 'Yaml two keys for element at line %d';
  EYamlExpectedKeyError = 'Yaml expected a key for element at line %d';
  EYamlDuplicatedKeyError = 'Yaml duplicated key name at line %d';
  EYamlAnchorNotFoundError = 'Yaml anchor "%s" not found for alias at line %d';
  EYamlAliasRecursiveError = 'Yaml unsupported recursive alias "%s" found at line %d';
  EYamlMergeInArrayError = 'Yaml merge indicator "<<" unsupported in arrays at line %d';
  EYamlMergeInCollectionError = 'Yaml merge indicator "<<" unsupported in collections at line %d';
  EYamlMergeSingleValueError = 'Yaml merge indicator "<<" unsupported for single values at line %d';
  EYamlMergeInvalidError = 'Yaml invalid merge indicator "<<" without alias reference at line %d';
  EYamlInvalidTagError = 'Yaml unreconized tag at line %d';
  EYamlInvalidValueForTagError = 'Yaml invalid value type for tag at line %d';

const
  LLiteralReplacer: AnsiString = chr(11) + chr(11);
  LLiteralLineFeed: AnsiString = chr(14) + chr(14);

const
  LTagMap: AnsiString = '!!map';               // Dictionary map {key: value}
  LTagSeq: AnsiString = '!!seq';               // Sequence (an array or collection)
  LTagStr: AnsiString = '!!str';               // Normal string (no conversion)
  LTagNull: AnsiString = '!!null';             // Null (must be null)
  LTagBool: AnsiString = '!!bool';             // Boolean (true/false)
  LTagInt: AnsiString = '!!int';               // Integer numeric
  LTagFloat: AnsiString = '!!float';           // Float numeric
  LTagBin: AnsiString = '!!binary';            // Binary time (array of bytes)
  LTagTime: AnsiString = '!!timestamp';        // Datetime type


// Sub-type TYamlElement
// ---------------------

class procedure TYamlUtils.TYamlElement.Initialize(out Dest: TYamlElement);
begin
  Dest.Key := '';
  Dest.Value := '';
  Dest.Indent := -1;
  Dest.Literal := False;
  Dest.Alias := '';
  Dest.Anchor := '';
  Dest.LineNumber := 0;
  Dest.Tag := '';
end;

class procedure TYamlUtils.TYamlElement.Assign(var Dest: TYamlElement; const Src: TYamlElement);
begin
  Dest.Key := Src.Key;
  Dest.Value := Src.Value;
  Dest.Indent := Src.Indent;
  Dest.Literal := Src.Literal;
  Dest.Alias := Src.Alias;
  Dest.Anchor := Src.Anchor;
  Dest.LineNumber := Src.LineNumber;
  Dest.Tag := Src.Tag;
end;

procedure TYamlUtils.TYamlElement.Clear;
begin
  Key := '';
  Value := '';
  Indent := -1;
  Literal := False;
  Alias := '';
  Anchor := '';
  LineNumber := 0;
  Tag := '';
end;

// TYamlUtils static class
// -----------------------

// Escape string for Yaml to Json conversion
// If ALiteral is true, the source is enclosed with double-quotes ("value") and backslash will not be escaped
class function TYamlUtils.InternalStringEscape(const AText: AnsiString): AnsiString;
var
  T: AnsiString;
  C: Ansistring;
begin
  T := AText;
  T := T.Replace('\', '\\');     // backslash
  T := T.Replace('"', '\"');     // double quotes
  T := T.Replace(#8, '\b');      // backspace
  T := T.Replace(#9, '\t');      // tab
  T := T.Replace(#10, '\n');     // line feed
  T := T.Replace(#12, '\f');     // form feed
  T := T.Replace(#13, '\r');     // cariage return

  // WWY: Fixed issues with the next unicode char constants, e.g. "#$2028"
  // When writing as before:
  //   T := T.Replace(#$2028, '\u2028')
  // this crashes js and/or the browser! Wrapping them in Chr() fixes this.

  C := #$C2#$85; // Chr($0085);
  T := T.Replace(C, '\u0085'); // new line (unicode)
  C := #$E2#$80#$A8; // Chr($2028);
  T := T.Replace(C, '\u2028'); // line separator (unicode)
  C := #$E2#$80#$A9; // Chr($2029);
  T := T.Replace(C, '\u2029'); // paragraph separator (unicode)

  T := T.Replace(LLiteralLineFeed, '\n'); // implicit line feed on literals
  Result := T;
end;

// Try convert a timestamp value to a datetime UTC
class function TYamlUtils.InternalTryStrToDateTime(const AText: AnsiString; var ADate: TDateTime; AFormatSettings: TFormatSettings): Boolean;
var
  Num: Integer;
  T: AnsiString;
  i: Integer;
begin
  T := AText;
  if TryStrToInt(T.Substring(0, 1), Num) then
  begin
    T := T.Replace('t', 'T');
    T := T.Replace('z', 'Z');
    // Check if we need to invert year i
    i := T.IndexOf('-');
    if i <= 2 then
      T := T.Substring(i + 4, 4) +  // Year
           T.Substring(i, 1) +      // Sep
           T.Substring(i + 1, 2) +  // Month
           T.Substring(i, 1) +      // Sep
           T.Substring(0, i) +      // Day
           T.Substring(i + 8);      // Remaining
    // Try ISO8601 conversion, converting to UTC
   {$IFNDEF PAS2JS}
    Result := DateUtils.TryISO8601ToDate(T, ADate, True);
   {$ELSE}
   // Function TryRFC3339ToDateTime(const Avalue: AnsiString; out ADateTime: TDateTime): Boolean;
   Result := DateUtils.TryRFC3339ToDateTime(LText, ADate);
   {$ENDIF}
    // Of try the usual way
    if not Result then
      Result := TryStrToDateTime(T, ADate, AFormatSettings);
  end
  else
    Result := False;
end;


// YAML to JSON section
// --------------------

// Read next text YAML line from strings
class function TYamlUtils.InternalYamlNextTextLine(AYAML: TStrings; var ARow, AIndent: Integer; AIgnoreBlanks: Boolean = True; AIgnoreComments: Boolean = True; AAutoTrim: Boolean = True): AnsiString;
var
  Row: Integer;
  Found: Boolean;
  T: AnsiString;
begin
  Row := ARow;
  Found := False;
  while (Row < AYAML.Count - 1) and (not Found) do
  begin
    Inc(Row);
    T := AYAML[Row].TrimLeft;
    if not ((T.StartsWith('#') and AIgnoreComments) or (T.Trim.IsEmpty and AIgnoreBlanks)) then
    begin
      Found := True;
      // If line is blank (in a multiline element), keep same indent
      if not T.Trim.IsEmpty then
        AIndent := AYAML[Row].Length - T.Length;
      T := AYAML[Row];
    end;
  end;
  if not Found then
  begin
    T := '';
    Row := -1;
    AIndent := -1;
  end;
  ARow := Row;
  if AAutoTrim then
    Result := T.Trim
  else
    Result := T;
end;


// Retrieve what next text will be
class function TYamlUtils.InternalYamlNextText(AYAML: TStrings; var ARow, AIndent: Integer; AText: AnsiString; AIgnoreBlanks: Boolean = True; AIgnoreComments: Boolean = True; AAutoTrim: Boolean = True): AnsiString;
begin
  if (AText.IsEmpty) or AText.StartsWith('#') then
    Result := InternalYamlNextTextLine(AYAML, ARow, AIndent, AIgnoreBlanks, AIgnoreComments, AAutoTrim)
  else
    Result := AText;
end;


// Read next token from source, with multiline support
class function TYamlUtils.InternalYamlReadToken(AYAML: TStrings; var ARow, AIndent: Integer; var AText, ARemainer, AAlias, ATag: AnsiString; var ACollectionItem: Integer; var AIsLiteral: Boolean; AInArray: Boolean = False): TYamlTokenType;
var
  TokenType: TYamlTokenType;
  T: AnsiString;
  Row: Integer;
  Indent: Integer;
  BlockModifier: TBlockModifier;
  ChompModifier: TChompModifier;
  Literal: AnsiString;
  LiteralMask: AnsiString;
  LFLiteral: AnsiString;
  Pos: Integer;
  Found: Boolean;
  NextRow: Integer;
  NextIndent: Integer;
  NextText: AnsiString;
  PrevRow: Integer;
  PrevIndent: Integer;
  Lines: TStringList;
  i, j: Integer;
  LinesCount: Integer;
  LeftMargin: Integer;
  Margin: Integer;
begin
  TokenType := TYamlTokenType.tokenValue;
  T := AText;
  Row := ARow;
  Indent := AIndent;
  PrevIndent := AIndent;
  PrevRow := ARow;
  BlockModifier := blockNone;
  ChompModifier := chompNone;
  Literal := '';
  LiteralMask := '';
  NextRow := -1;
  NextIndent := -1;
  NextText := '';
  LinesCount := 0;
  ACollectionItem := 0;
  AIsLiteral := False;
  ARemainer := '';
  AAlias := '';
  ATag := '';

  if T.IsEmpty or T.StartsWith('#') then
    T := InternalYamlNextTextLine(AYAML, Row, Indent, True, True);

  // If reached EOF, exit
  if Row < 0 then
  begin
    ARow := -1;
    AIndent := -1;
    AText := '';
    Exit(TokenType);
  end;

  // Check for tags
  if T.ToLower.Trim.Equals(LTagMap) or T.ToLower.StartsWith(LTagMap + ' ') then
    ATag := LTagMap
  else if T.ToLower.Trim.Equals(LTagSeq) or T.ToLower.StartsWith(LTagSeq + ' ') then
    ATag := LTagSeq
  else if T.ToLower.Trim.Equals(LTagStr) or T.ToLower.StartsWith(LTagStr + ' ') then
    ATag := LTagStr
  else if T.ToLower.Trim.Equals(LTagNull) or T.ToLower.StartsWith(LTagNull + ' ') then
    ATag := LTagNull
  else if T.ToLower.Trim.Equals(LTagBool) or T.ToLower.StartsWith(LTagBool + ' ') then
    ATag := LTagBool
  else if T.ToLower.Trim.Equals(LTagInt) or T.ToLower.StartsWith(LTagInt + ' ') then
    ATag := LTagInt
  else if T.ToLower.Trim.Equals(LTagFloat) or T.ToLower.StartsWith(LTagFloat + ' ') then
    ATag := LTagFloat
  else if T.ToLower.Trim.Equals(LTagBin) or T.ToLower.StartsWith(LTagBin + ' ') then
    ATag := LTagBin
  else if T.ToLower.Trim.Equals(LTagTime) or T.ToLower.StartsWith(LTagTime + ' ') then
    ATag := LTagTime
  else if T.ToLower.StartsWith('!!') then
    raise EYamlParsingException.CreateFmt(EYamlInvalidTagError, [Row + 1])
  else if T.StartsWith('!') then
    ATag := T.Substring(0, T.IndexOf(' '));
  if not ATag.IsEmpty then
  begin
    T := T.Substring(ATag.Length).TrimLeft;
    if T.IsEmpty then
    begin
      ARow := Row;
      AIndent := Indent;
      AText := '';
      Exit(TokenType);
    end;
  end;

  // Check for inner array start/end/separator
  if T.StartsWith('[') or (AInArray and (T.StartsWith(']') or T.StartsWith(','))) then
  begin
    ARemainer := T.Substring(1).Trim;
    AText := T.Substring(0, 1);
    ARow := Row;
    AIndent := Indent;
    Exit(TokenType);
  end;

  // Check if it is a collection item
  if (T.StartsWith('- ')) and (not AInArray) then
  begin
    if not (T.StartsWith('- ') or T.Equals('-')) then
      raise EYamlParsingException.CreateFmt(EYamlCollectionItemError, [Row + 1]);
    ACollectionItem := (T.Substring(1).Length) - (T.Substring(1).TrimLeft().Length) + 1;
    if ACollectionItem <= 0 then
      ACollectionItem := 2;
    T := T.Substring(1).Trim;
  end;

  // Check for alias/anchor/references
  if T.StartsWith('&') or T.StartsWith('*') then
  begin
    if T.Substring(1).StartsWith(' ') then
      raise EYamlParsingException.CreateFmt(EYamlAnchorAliasNameError, [Row + 1]);
    if AInArray then
      Pos := T.IndexOfAny([' ', ','])
    else
      Pos := T.IndexOf(' ');
    if Pos >= 0 then
    begin
      AAlias := T.Substring(0, Pos).Trim;
      T := T.Substring(Pos).Trim;
    end
    else
    begin
      AAlias := T;
      T := '';
    end;
    // Evaluate that the alias is a valid name
    if (not SysUtils.IsValidIdent(AAlias.Substring(1), False)) then
      raise EYamlParsingException.CreateFmt(EYamlAnchorAliasNameError, [Row + 1]);
  end;

  // Check for block/folder modifiers, multiline related
  // If they are present, this must be a value
  if T.StartsWith('|') or T.StartsWith('>') then
  begin
    if ACollectionItem > 0 then
      raise EYamlParsingException.CreateFmt(EYamlCollectionBlockError, [Row + 1]);
    if T.StartsWith('|') then
      BlockModifier := blockLiteral
    else
      BlockModifier := blockFolded;
    T := T.Substring(1).Trim;
    if T.StartsWith('+') or T.StartsWith('-') then
    begin
      if T.StartsWith('+') then
        ChompModifier := chompKeep
      else
        ChompModifier := chompClip;
      T := T.Substring(1).Trim;
    end;
  end;

  // Check for literals (starting with " or with ' )
  if T.StartsWith('"') then
  begin
    Literal := '"';
    LiteralMask := '\"';
  end
  else if T.StartsWith('''') then
  begin
    Literal := '''';
    LiteralMask := '''''';
  end;

  // Read the token, check if multilines are actually there, to avoid multiline strings processing if not needed
  // When not found, multilines are present so we will have to keep reading
  Found := False;
  // Is it literal
  if not Literal.IsEmpty then
  begin
    T := T.Substring(1).Replace(LiteralMask, LLiteralReplacer);
    Pos := T.IndexOf(Literal);
    // Closure found inline
    if Pos >= 0 then
    begin
      Found := True;
      ARemainer := T.Substring(Pos + 1).Replace(LLiteralReplacer, LiteralMask).Trim;
      T := T.Substring(0, Pos).Replace(LLiteralReplacer, Literal);
    end;
  end
  else
  begin
    // Check for inline array element termination
    if AInArray then
    begin
      Pos := T.IndexOfAny([',', ']']);
      if Pos >= 0 then
      begin
        Found := True;
        ARemainer := T.Substring(Pos) + ARemainer;
        T := T.Substring(0, Pos);
      end;
    end;
    // Check for inline key: value termination
    Pos := T.IndexOf(': ');
    if (Pos < 0) and T.EndsWith(':') then
      Pos := T.Length - 1;
    if Pos >= 0 then
    begin
      Found := True;
      ARemainer := T.Substring(Pos) + ARemainer;
      T := T.Substring(0, Pos);
    end;
    // Still not found, so take a look at next row and evaluate termination
    if not Found then
    begin
      NextRow := Row;
      NextIndent := Indent;
      NextText := InternalYamlNextText(AYAML, NextRow, NextIndent, ARemainer, True, True);
      // EOF
      if NextRow < 0 then
        Found := True
      // Collection item failure
      else if (ACollectionItem > 0) and (NextRow = Row) then
        raise EYamlParsingException.CreateFmt(EYamlCollectionItemError, [Row + 1])
      // Another collection item at the same level
      else if (ACollectionItem > 0) and (NextIndent = Indent) and (NextText.StartsWith('- ') or NextText.Equals('-')) then
        Found := True
      // A collection is starting
      else if (ACollectionItem <= 0) and (NextIndent >= Indent) and (NextText.StartsWith('- ') or NextText.Equals('-')) then
        Found := True
      // New element or outdenting
      else if (NextIndent <= AIndent) then
        Found := True
      // Indenting new key
      else if (NextIndent > AIndent) and (NextText.EndsWith(':') or (NextText.IndexOf(': ') >= 0)) then
        Found := True;
      // In case multiline starts at next row
      if (Row > PrevRow) and (PrevIndent < Indent) then
        Indent := PrevIndent;
    end;
  end;

  // Not found, go for multilines
  if (not Found) and (Row >= 0) and (Row < AYAML.Count - 1) then
  begin
    NextRow := Row;
    NextIndent := AIndent;
    Lines := TStringList.Create;
    try
      if not T.IsEmpty then
        Lines.Add(T);
      while (not Found) and (NextRow >= 0) do
      begin
        T := InternalYamlNextTextLine(AYAML, NextRow, NextIndent, False, (not Literal.IsEmpty), False);
        // Literal text, must find text closure
        if (not Literal.IsEmpty) then
        begin
          T := T.Replace(LiteralMask, LLiteralReplacer);
          Pos := T.IndexOf(Literal);
          if Pos >= 0 then
          begin
            Found := True;
            ARemainer := T.Substring(Pos + 1).Replace(LLiteralReplacer, LiteralMask).Trim;
            Lines.Add(T.Substring(0, Pos));
          end
          else
            Lines.Add(T);
          Row := NextRow;
        end
        // Reached EOF
        else if (NextRow < 0) then
          Found := True
        else
        begin
          // Outdenting or new element
          if (NextIndent <= Indent) and (not AInArray) and (not T.Trim.IsEmpty) then
            Found := True
          // Another collection item at the same level
          else if (ACollectionItem > 0) and (NextIndent = Indent) and (NextText.StartsWith('- ') or NextText.Equals('-')) then
            Found := True
          // Collection item starting
          else if (ACollectionItem <= 0) and (not AInArray) and (NextIndent >= Indent) and (NextText.StartsWith('- ') or NextText.Equals('-')) then
            Found := True
          // Splitted line ending
          else
          begin
            Pos := -1;
            if AInArray then
              Pos := T.IndexOfAny([',', ']', '[']);
            if Pos < 0 then
              Pos := T.IndexOf(': ');
            if (Pos < 0) and T.EndsWith(':') then
              Pos := T.Length - 1;
            if Pos >= 0 then
            begin
              Found := True;
              ARemainer := T.Substring(Pos).Trim;
              Lines.Add(T.Substring(0, Pos));
            end;
          end;
          // Not found inline, add new line
          if (not Found) then
          begin
            Lines.Add(T);
            Row := NextRow;
          end;
        end;
      end;
      // All lines were read.
      // Process them according literal/scallar/chomp options
      LinesCount := Lines.Count;
      // Top empty lines are only kept if literal is " or we have a folder modified
      if (Found) and (BlockModifier = blockNone) and (not Literal.Equals('"')) then
      begin
        while (Lines.Count > 0) and (Lines[0].Trim.IsEmpty) do
          Lines.Delete(0);
      end;
      // Bottom empty lines are only kept if literal is " or chomp modifier is +
      if (Found) and (ChompModifier <> chompKeep) and (not Literal.Equals('"')) then
      begin
        i := Lines.Count - 1;
        while (i >= 0) and (Lines[i].Trim.IsEmpty) do
        begin
          Lines.Delete(i);
          Dec(i);
        end;
      end;
      // Compute multiline left alignment
      if (Found) then
      begin
        LeftMargin := -1;
        for i := 1 to Lines.Count - 1 do
        begin
          if not Lines[i].IsEmpty then
          begin
            T := Lines[i];
            Margin := Lines[i].Length - Lines[i].TrimLeft.Length;
            if (LeftMargin <= 0) or (Margin < LeftMargin) then
              LeftMargin := Margin;
          end;
        end;
        if Lines.Count > 0 then
          Lines[0] := String.Create(' ', LeftMargin) + Lines[0];
        for i := 0 to Lines.Count - 1 do
          Lines[i] := Lines[i].Substring(LeftMargin);
      end;
      // Convert it back to a single text for json
      if (Found) then
      begin
        T := '';
        if ATag = LTagBin then
          LFLiteral := ''
        else
          LFLiteral := LLiteralLineFeed;
        for i := 0 to Lines.Count - 1 do
        begin
          if Lines[i].Trim.IsEmpty then
            T := T + LFLiteral
          else if BlockModifier = blockLiteral then
            T := T + Lines[i] + LFLiteral
          else if Lines[i].StartsWith(' ') and (BlockModifier <> blockNone) then
          begin
            if T.IsEmpty then
              T := T + Lines[i] + LFLiteral
            else if (i > 0) and (Lines[i - 1].Trim.IsEmpty or Lines[i - 1].StartsWith(' ')) then
              T := T + Lines[i] + LFLiteral
            else
              T := T + LFLiteral + Lines[i] + LFLiteral;
          end
          else
          begin
            if not (T.IsEmpty or T.EndsWith(LFLiteral) or T.EndsWith(' ')) then
              T := T + ' ';
            if (BlockModifier = blockNone) then
              T := T + Lines[i].Trim()
            else
              T := T + Lines[i];
          end;
        end;
        if (BlockModifier = blockFolded) and (ChompModifier <> chompClip) then
          T := T + LFLiteral;
        if T.EndsWith(LFLiteral) and (ChompModifier = chompClip) then
          T := T.Substring(0, T.Length - LFLiteral.Length);
        if (not Literal.IsEmpty) then
          T := T.Replace(LLiteralReplacer, Literal);
      end;
    finally
      FreeAndNil(Lines);
    end;
  end;

  // If unclosed literal element, raise
  if (not Found) and (not Literal.IsEmpty) then
    raise EYamlParsingException.CreateFmt(EYamlUnclosedLiteralError, [Row + 1]);

  // Check for key type
  if (ARemainer = ':') or ARemainer.StartsWith(': ') or (AInArray and ARemainer.StartsWith(':,')) then
  begin
    TokenType := TYamlTokenType.tokenKey;
    ARemainer := ARemainer.Substring(1).Trim;
    // Keys cannot be empty
    if T.IsEmpty then
      raise EYamlParsingException.CreateFmt(EYamlKeyNameEmptyError, [Row + 1]);
    // Keys cannot be multiline
    if LinesCount > 1 then
      raise EYamlParsingException.CreateFmt(EYamlKeyNameMultilineError, [Row + 1]);
    // Keys cannot have aliases/anchors
    if not AAlias.IsEmpty then
      raise EYamlParsingException.CreateFmt(EYamlKeyNameAnchorAliasError, [Row + 1]);
    // Check accepted initial chars for keys
    if SysUtils.CharInSet(T.Chars[0], ['[', ',', ']', '-', '&', '*', '|', '>', '+']) then
      raise EYamlParsingException.CreateFmt(EYamlKeyNameInvalidCharError, [T.Substring(0, 1), Row + 1]);
  end;

  // Check for anchor reference with value
  if (not AAlias.IsEmpty) and (AAlias.StartsWith('*')) and (not T.IsEmpty) then
    raise EYamlParsingException.CreateFmt(EYamlAnchorAliasValueError, [Row + 1]);

  AIsLiteral := not Literal.IsEmpty;
  ARow := Row;
  AIndent := Indent;
  if AIsLiteral then
    AText := InternalStringEscape(T)
  else begin
    j := T.IndexOf('# ');
    if j >= 0 then
      T := T.Remove(j).TrimRight;
    AText := InternalStringEscape(T.Trim([' ']));
  end;
  Result := TokenType;
end;


// Find element containing an anchor by anchor name
class function TYamlUtils.InternalYamlFindAnchor(AElements: TYamlElements; AAnchorName: AnsiString): Integer;
var
  i: Integer;
begin
  if not AAnchorName.IsEmpty then
    for i := 0 to AElements.Count - 1 do
      if AElements[i].Anchor.Equals(AAnchorName) then
        Exit(i);
  Result := -1;
end;


// Resolve (pre-process) aliases to anchor values
class procedure TYamlUtils.InternalYamlResolveAliases(AElements: TYamlElements);
var
  i: Integer;
  Anchor: Integer;
  Alias: Integer;
  AliasName: AnsiString;
  AliasElement: TYamlElement;
  AnchorElement: TYamlElement;
  Element: TYamlElement;
  Done: Boolean;
  RefIndent: Integer;
  SubElements: TYamlElements;
begin
  if AElements.Count = 0 then
    Exit;
  Done := False;
  while not Done do
  begin
    Alias := -1;
    AliasName := '';
    i := 0;
    while (AliasName.IsEmpty) and (i < AElements.Count) do
    begin
      if (not AElements[i].Alias.IsEmpty) and (not AElements[i].Key.Equals('<<')) then
      begin
        Alias := i;
        AliasName := AElements[i].Alias;
        AliasElement := AElements[i];
      end
      else
        Inc(i);
    end;
    if AliasName.IsEmpty then
      Done := True
    else
    begin
      AliasElement.Alias := '';
      AElements[Alias] := AliasElement;
      // Find the enchor
      Anchor := InternalYamlFindAnchor(AElements, AliasName);
      if Anchor < 0 then
        raise EYamlParsingException.CreateFmt(EYamlAnchorNotFoundError, [AliasName, AliasElement.LineNumber]);
      AnchorElement := AElements[Anchor];
      // Is it a single value reference ?
      if not AnchorElement.Value.IsEmpty then
      begin
        AliasElement.Value := AnchorElement.Value;
        AliasElement.Literal := AnchorElement.Literal;
        AliasElement.Tag := AnchorElement.Tag;
        AElements[Alias] := AliasElement;
      end
      // Is it a subchain reference ?
      else
      begin
        RefIndent := AnchorElement.Indent;
        SubElements := TYamlElements.Create;
        try
          i := Anchor + 1;
          while (i > 0) and (i < AElements.Count) do
          begin
            if AElements[i].Indent > RefIndent then
            begin
              if (AElements[i].Alias = AliasName) then
                raise EYamlParsingException.CreateFmt(EYamlAliasRecursiveError, [AliasName, AElements[i].LineNumber]);
              Element := AElements[i];
              Element.Indent := Element.Indent - RefIndent + AliasElement.Indent;
              SubElements.Add(Element);
              Inc(i);
            end
            else
              i := -1;
          end;
          if SubElements.Count > 0 then
            AElements.InsertRange(Alias + 1, SubElements);
        finally
          FreeAndNil(SubElements);
        end;
      end;
    end;
  end;
end;

// Merge (pre-process) aliases with anchor values
class procedure TYamlUtils.InternalYamlResolveMerges(AElements: TYamlElements);
var
  i, j: Integer;
  Anchor: Integer;
  Alias: Integer;
  AliasName: AnsiString;
  AliasElement: TYamlElement;
  AnchorElement: TYamlElement;
  Done: Boolean;
  Element: TYamlElement;
  RefIndent: Integer;
  BaseIndent: Integer;
  RefParent: Integer;
  SubElements: TYamlElements;
  AnchorElements: TYamlElements;
  MergeElements: TYamlElements;
  Index: Integer;
  Indent: Integer;

  function __FindExistingElement(AList: TYamlElements; AElement: TYamlElement): Integer;
  var
    k: Integer;
  begin
    for k := 0 to AList.Count - 1 do
    begin
      if (AList[k].Indent = AElement.Indent) and
        ((not AElement.Key.IsEmpty and AElement.Key.Equals(AList[k].Key)) or
        (AElement.Key.IsEmpty and AElement.Value.Equals(AList[k].Value))) then
        Exit(k);
    end;
    Result := -1;
  end;

begin
  if AElements.Count = 0 then
    Exit;
  SubElements := nil;
  MergeElements := nil;
  try
    SubElements := TYamlElements.Create;
    AnchorElements := TYamlElements.Create;
    MergeElements := TYamlElements.Create;
    Done := False;
    while not Done do
    begin
      Alias := -1;
      AliasName := '';
      i := 0;
      while (AliasName.IsEmpty) and (i < AElements.Count) do
      begin
        if (not AElements[i].Alias.IsEmpty) and (AElements[i].Key.Equals('<<')) then
        begin
          Alias := i;
          AliasName := AElements[i].Alias;
          AliasElement := AElements[i];
        end
        else
          Inc(i);
      end;
      if AliasName.IsEmpty then
        Done := True
      else
      begin
        // Find the enchor
        Anchor := InternalYamlFindAnchor(AElements, AliasName);
        if Anchor < 0 then
          raise EYamlParsingException.CreateFmt(EYamlAnchorNotFoundError, [AliasName, AliasElement.LineNumber]);
        AnchorElement := AElements[Anchor];
        // Is it a single value reference ?
        if not AnchorElement.Value.IsEmpty then
          raise EYamlParsingException.CreateFmt(EYamlMergeSingleValueError, [AliasName, AliasElement.LineNumber]);
        // Find the relative root
        RefIndent := AliasElement.Indent;
        BaseIndent := 0;
        RefParent := -1;
        i := Alias - 1;
        while (i >= 0) and (RefParent = -1) do
        begin
          if AElements[i].Indent < RefIndent then
          begin
            RefParent := i;
            BaseIndent := AElements[i].Indent;
          end
          else
            Dec(i);
        end;
        // Get the anchor elements
        RefIndent := AnchorElement.Indent;
        AnchorElements.Clear;
        i := Anchor + 1;
        while (i > 0) and (i < AElements.Count) do
        begin
          if AElements[i].Indent > RefIndent then
          begin
            if (AElements[i].Alias = AliasName) then
              raise EYamlParsingException.CreateFmt(EYamlAliasRecursiveError, [AliasName, AElements[i].LineNumber]);
            Element := AElements[i];
            Element.Indent := Element.Indent - RefIndent + BaseIndent;
            AnchorElements.Add(Element);
            Inc(i);
          end
          else
            i := -1;
        end;
        // Read existing elements to merge with and removed them from chain (they will be reinserted after merging)
        MergeElements.Clear;
        RefIndent := AliasElement.Indent;
        i := RefParent + 1;
        while (i > 0) and (i < AElements.Count) do
        begin
          if AElements[i].Indent >= RefIndent then
          begin
            if not (AElements[i].Alias = AliasName) then
            begin
              Element := AElements[i];
              MergeElements.Add(Element);
            end;
            AElements.Delete(i);
          end
          else
            i := -1;
        end;
        // Remove existing arrays/collections from anchor elements as the do not merge
        for i := 0 to MergeElements.Count - 1 do
        begin
          Element := MergeElements[i];
          if not Element.Key.IsEmpty then
          begin
            Index := __FindExistingElement(AnchorElements, Element);
            if (Index >= 0) and (Index < AnchorElements.Count - 1) and (AnchorElements[Index + 1].Key.IsEmpty) and (AnchorElements[Index + 1].Value.Equals('[')) then
            begin
              // Remove the array chain
              j := Index + 1;
              AnchorElement := AnchorElements[j];
              Indent := AnchorElement.Indent;
              while (j >= 0) and (AnchorElements.Count > j) do
              begin
                AnchorElements.Delete(j);
                if (AnchorElement.Indent = Indent) and (AnchorElement.Key.IsEmpty) and (AnchorElement.Value.Equals(']')) then
                  j := -1
                else if (AnchorElements.Count > j) then
                  AnchorElement := AnchorElements[j];
              end;
              AnchorElements.Delete(Index);
            end;
          end;
        end;
        // Do the merge
        SubElements.Clear;
        while AnchorElements.Count > 0 do
        begin
          AnchorElement := AnchorElements[0];
          Index := __FindExistingElement(MergeElements, AnchorElement);
          if Index >= 0 then
          begin
            AnchorElement.Key := MergeElements[Index].Key;
            AnchorElement.Value := MergeElements[Index].Value;
            AnchorElement.Literal := MergeElements[Index].Literal;
            AnchorElement.Tag := MergeElements[Index].Tag;
            MergeElements.Delete(Index);
          end;
          SubElements.Add(AnchorElement);
          AnchorElements.Delete(0);
          // Check for orphans
          if MergeElements.Count > 0 then
          begin
            AliasElement := MergeElements[0];
            Index := __FindExistingElement(AnchorElements, AliasElement);
            while (Index < 0) and (MergeElements.Count > 0) do
            begin
              SubElements.Add(AliasElement);
              MergeElements.Delete(0);
              if MergeElements.Count > 0 then
              begin
                AliasElement := MergeElements[0];
                Index := __FindExistingElement(AnchorElements, AliasElement);
              end;
            end;
          end;
        end;
        if SubElements.Count > 0 then
          AElements.InsertRange(RefParent + 1, SubElements);
      end;
    end;
  finally
    FreeAndNil(AnchorElements);
    FreeAndNil(MergeElements);
    FreeAndNil(SubElements);
  end;
end;


// Process an inline array from source
class procedure TYamlUtils.InternalYamlProcessArray(AYAML: TStrings; AElements: TYamlElements; var ARow, AIndent: Integer; var AText: AnsiString; AYesNoBool: Boolean; AAllowDuplicateKeys: Boolean);
var
  TokenType: TYamlTokenType;
  Element: TYamlElement;
  XElement: TYamlElement;
  ElementIndent: Integer;
  Row: Integer;
  CurrRow: Integer;
  Indent: Integer;
  T: AnsiString;
  Remainer: AnsiString;
  Alias: AnsiString;
  Tag: AnsiString;
  CollectionItem: Integer;
  IsLiteral: Boolean;
  LastSeparator: AnsiString;
  Done: Boolean;
  Closed: Boolean;
  NextRow: Integer;
  NextIndent: Integer;
  NextText: AnsiString;
begin
  ElementIndent := 0;
  Row := ARow;
  CurrRow := ARow;
  Indent := AIndent;
  T := AText;
  Remainer := AText;
  Alias := '';
  CollectionItem := 0;
  IsLiteral := False;
  LastSeparator := '[';
  Done := False;
  Closed := False;
  NextRow := -1;
  NextIndent := -1;
  NextText := '';

  // Get last element in elements list, if it exists, and indent from it
  if AElements.Count > 0 then
  begin
    if (AElements.Last.Value = ']') and (AElements.Last.Key.IsEmpty()) then
      ElementIndent := AElements.Last.Indent
    else
      ElementIndent := AElements.Last.Indent + 1;
  end;

  // Absorbe the first [ text and open the array
  InternalYamlReadToken(AYAML, Row, Indent, T, Remainer, Alias, Tag{%H-}, CollectionItem, IsLiteral, True);
  if not T.Equals('[') then
    raise EYamlParsingException.CreateFmt(EYamlInvalidArrayError, [Row + 1]);
  LastSeparator := '[';
  Element.Indent := ElementIndent;
  Element.LineNumber := Row + 1;
  Element.Value := '[';
  AElements.Add(Element);
  Element.Clear;

  while not Done do
  begin

    // Did we reach EOF ?
    if Row < 0 then
      Done := True
    else
    begin

      Element.Indent := ElementIndent;
      T := Remainer;

      // Check what will be next, in case we need to jump somewhere
      CurrRow := Row;
      NextRow := Row;
      NextIndent := Indent;
      NextText := InternalYamlNextText(AYAML, NextRow, NextIndent, Remainer, True, True);

      // We have an array inside an array
      if NextText.StartsWith('[') then
      begin
        InternalYamlProcessArray(AYAML, AElements, Row, NextIndent, Remainer, AYesNoBool, AAllowDuplicateKeys);
        LastSeparator := ']';
      end
      else
      begin
        TokenType := InternalYamlReadToken(AYAML, Row, Indent, T, Remainer, Alias, Tag, CollectionItem, IsLiteral, True);
        // Array is being closed, absorve it
        if T = ']' then
        begin
          Element.LineNumber := Row + 1;
          if (LastSeparator = ',') and not NextText.StartsWith('[') then
          begin
            Element.Value := 'null';
            AElements.Add(Element);
          end;
          Element.Value := ']';
          AElements.Add(Element);
          Element.Clear;
          Closed := True;
          Done := True;
          LastSeparator := ']';
        end
        // Array element split, absorve it
        else if T = ',' then
        begin
          if (LastSeparator = ',') or (LastSeparator = '[') then
          begin
            Element.Value := 'null';
            Element.LineNumber := Row + 1;
            AElements.Add(Element);
            Element.Clear;
          end;
          LastSeparator := ',';
        end
        // Go for the data
        else
        begin
          LastSeparator := '';
          // Inline arrays do not support collection items
          if ((CollectionItem > 0) or T.StartsWith('- ') or T.Equals('-')) and (not IsLiteral) then
            raise EYamlParsingException.CreateFmt(EYamlCollectionInArrayError, [Row + 1]);
          if (TokenType = TYamlTokenType.tokenKey) then
          begin
            if T.Equals('<<') then
              raise EYamlParsingException.CreateFmt(EYamlMergeInArrayError, [Row + 1]);
            Element.Key := T;
            T := Remainer;
            TokenType := InternalYamlReadToken(AYAML, Row, Indent, T, Remainer, Alias, Tag, CollectionItem, IsLiteral, True);
            // Inline element with two keys
            if TokenType = TYamlTokenType.tokenKey then
              raise EYamlParsingException.CreateFmt(EYamlDoubleKeyError, [Row + 1]);
            // Inline arrays do not support collection items
            if ((CollectionItem > 0) or T.StartsWith('- ') or T.Equals('-')) and (not IsLiteral) then
              raise EYamlParsingException.CreateFmt(EYamlCollectionInArrayError, [Row + 1]);
            if T = ',' then
            begin
              Remainer := T + Remainer;
              T := '';
            end;
          end;
          Element.Literal := IsLiteral;
          Element.Tag := Tag;
          if not Alias.IsEmpty then
          begin
            if Alias.StartsWith('*') then
              Element.Alias := Alias.Substring(1)
            else
            begin
              Element.Anchor := Alias.Substring(1);
              // Avoid duplicated anchor names
              if InternalYamlFindAnchor(AElements, Element.Anchor) >= 0 then
                raise EYamlParsingException.CreateFmt(EYamlAnchorDuplicateError, [Row + 1]);
            end;
          end;
          if not Element.Key.IsEmpty then
          begin
            XElement.Indent := ElementIndent + 1;
            XElement.LineNumber := Row + 1;
            XElement.Value := '{';
            AElements.Add(XElement);
            Element.Indent := ElementIndent + 1;
          end;
          if T.IsEmpty then
            Element.Value := 'null'
          else
            Element.Value := T;
          Element.LineNumber := Row + 1;
          AElements.Add(Element);
          if not Element.Key.IsEmpty then
          begin
            XElement.Indent := ElementIndent + 1;
            XElement.LineNumber := Row + 1;
            XElement.Value := '}';
            AElements.Add(XElement);
          end;
          Element.Clear;
        end;
      end;
    end;

  end;

  if not Closed then
    raise EYamlParsingException.CreateFmt(EYamlUnclosedArrayError, [Row + 1]);
  ARow := CurrRow;
  AText := Remainer;
end;


// Process a collection (array) from source
class procedure TYamlUtils.InternalYamlProcessCollection(AYAML: TStrings; AElements: TYamlElements; var ARow, AIndent: Integer; var AText: AnsiString; AYesNoBool: Boolean; AAllowDuplicateKeys: Boolean);
var
  TokenType: TYamlTokenType;
  Element: TYamlElement;
  ElementIndent: Integer;
  Done: Boolean;
  Row: Integer;
  CurrRow: Integer;
  Indent: Integer;
  T: AnsiString;
  Remainer: AnsiString;
  NextRow: Integer;
  NextIndent: Integer;
  NextText: AnsiString;
  ItemsIndent: Integer;
  Alias: AnsiString;
  Tag: AnsiString;
  //LPrevRemainer: AnsiString;
  IsLiteral: Boolean;
  CollectionItem: Integer;
begin
  ElementIndent := 0;
  Done := False;
  Row := ARow;
  CurrRow := ARow;
  Indent := AIndent;
  T := AText;
  Remainer := AText;
  NextRow := 0;
  NextIndent := AIndent;
  NextText := '';
  ItemsIndent := -1;
  Alias := '';
  //LPrevRemainer     := '';
  IsLiteral := False;
  CollectionItem := 0;

  // Get last element in elements list, if it exists, and indent from it
  if AElements.Count > 0 then
  begin
    if AElements.Last.Key.IsEmpty() and (AElements.Last.Value.Equals('}') or AElements.Last.Value.Equals(']')) then
      ElementIndent := AElements.Last.Indent
    else
      ElementIndent := AElements.Last.Indent + 1;
    if (not AElements.Last.Value.IsEmpty()) and (T.IsEmpty) then
    begin
      // Just get next row number for the message
      InternalYamlNextText(AYAML, Row, Indent, Remainer, True, True);
      raise EYamlParsingException.CreateFmt(EYamlCollectionItemError, [Row + 1]);
    end;
  end;

  // Put in the opener
  Element.Indent := ElementIndent;
  Element.LineNumber := Row + 1;
  Element.Value := '[';
  AElements.Add(Element);
  Element.Clear;

  while not Done do
  begin

    Element.Indent := ElementIndent;
    T := Remainer;

    // Check what will be next, in case we need to jump somewhere
    NextRow := Row;
    NextIndent := Indent;
    NextText := InternalYamlNextText(AYAML, NextRow, NextIndent, Remainer, True, True);
    // To control collection items alignment
    if ItemsIndent = -1 then
      ItemsIndent := NextIndent;

    // EOF
    if NextRow < 0 then
      Done := True
    // Outdent, exit
    else if NextIndent < ItemsIndent then
      Done := True
    // Next is not a collection item, exit
    else if (NextIndent = ItemsIndent) and not (NextText.StartsWith('- ') or NextText.Equals('-')) then
      Done := True
    // Go for it
    else
    begin

      // Backup references
      // LPrevRemainer := Remainer;

      // Read an item
      TokenType := InternalYamlReadToken(AYAML, Row, Indent, T, Remainer, Alias, Tag{%H-}, CollectionItem, IsLiteral, False);
      CurrRow := Row;

      // A trouple chain in item
      if (TokenType = TYamlTokenType.tokenKey) then
      begin
        if T.Equals('<<') then
          raise EYamlParsingException.CreateFmt(EYamlMergeInCollectionError, [Row + 1]);
        Indent := Indent + CollectionItem;
        Remainer := T + ': ' + Remainer;
        InternalYamlProcessElements(AYAML, AElements, Row, Indent, Remainer, AYesNoBool, AAllowDuplicateKeys);
        Indent := Indent - CollectionItem;
        CurrRow := Row;
      end
      // An inline array in item
      else if T.StartsWith('[') then
      begin
        Remainer := T;
        InternalYamlProcessArray(AYAML, AElements, Row, Indent, Remainer, AYesNoBool, AAllowDuplicateKeys);
        CurrRow := Row;
      end
      else
      begin
        if T.IsEmpty then
          Element.Value := 'null'
        else
          Element.Value := T;
        Element.Literal := IsLiteral;
        Element.Tag := Tag;
        if not Alias.IsEmpty then
        begin
          if Alias.StartsWith('*') then
            Element.Alias := Alias.Substring(1)
          else
          begin
            Element.Anchor := Alias.Substring(1);
            // Avoid duplicated anchor names
            if InternalYamlFindAnchor(AElements, Element.Anchor) >= 0 then
              raise EYamlParsingException.CreateFmt(EYamlAnchorDuplicateError, [Row + 1]);
          end;
        end;

        Element.LineNumber := Row + 1;
        AElements.Add(Element);
        Element.Clear;
      end;
    end;

  end;

  // Put in the closer
  Element.Indent := ElementIndent;
  Element.LineNumber := CurrRow + 1;
  Element.Value := ']';
  AElements.Add(Element);
  Element.Clear;

  ARow := CurrRow;
  AText := Remainer;
end;


// Process element pairs (key: value) from source
class procedure TYamlUtils.InternalYamlProcessElements(AYAML: TStrings; AElements: TYamlElements; var ARow, AIndent: Integer; var AText: AnsiString; AYesNoBool: Boolean; AAllowDuplicateKeys: Boolean);
var
  TokenType: TYamlTokenType;
  Element: TYamlElement;
  ElementIndent: Integer;
  Row: Integer;
  CurrRow: Integer;
  Indent: Integer;
  T: AnsiString;
  Remainer: AnsiString;
  KeysList: TStringList;
  Done: Boolean;
  NextRow: Integer;
  NextIndent: Integer;
  NextText: AnsiString;
  Alias: AnsiString;
  Tag: AnsiString;
  CollectionItem: Integer;
  IsLiteral: Boolean;
  PrevRow: Integer;
  PrevIndent: Integer;
  PrevRemainer: AnsiString;
begin
  ElementIndent := 0;
  Row := ARow;
  CurrRow := ARow;
  Indent := AIndent;
  T := AText;
  Remainer := AText;
  KeysList := nil;
  Done := False;
  NextRow := 0;
  NextIndent := AIndent;
  NextText := '';
  Alias := '';
  CollectionItem := 0;
  IsLiteral := False;
  PrevRemainer := '';

  // Get last element in elements list, if it exists, and indent from it
  if AElements.Count > 0 then
  begin
    Element := AElements.Last;
    if Element.Key.IsEmpty() and (Element.Value.Equals('}') or Element.Value.Equals(']')) then
      ElementIndent := Element.Indent
    else
      ElementIndent := Element.Indent + 1;
    if T.IsEmpty and ((not Element.Value.IsEmpty) and (Element.Value <> '}')) then
    begin
      // Just get next row number for the message
      InternalYamlNextText(AYAML, Row, Indent, Remainer, True, True);
      raise EYamlParsingException.CreateFmt(EYamlInvalidIndentError, [Row + 1]);
    end;
    Element.Clear;
  end;

  // Put in the opener
  Element.Indent := ElementIndent;
  Element.LineNumber := Row + 1;
  Element.Value := '{';
  AElements.Add(Element);
  Element.Clear;

  // Control duplicated keys, if required
  if not AAllowDuplicateKeys then
  begin
    KeysList := TStringList.Create;
    KeysList.CaseSensitive := True;
  end;
  try

    while not Done do
    begin

      Element.Indent := ElementIndent;
      T := Remainer;

      // Check what will be next, in case we need to jump somewhere
      NextRow := Row;
      NextIndent := Indent;
      NextText := InternalYamlNextText(AYAML, NextRow, NextIndent, Remainer, True, True);

      // EOF
      if NextRow < 0 then
        Done := True
      // Outdent / exit
      else if (Indent <> -1) and (NextIndent < Indent) then
        Done := True
      // A collection, process it
      else if NextText.StartsWith('- ') or NextText.Equals('-') then
      begin
        if NextRow = Row then
          raise EYamlParsingException.CreateFmt(EYamlCollectionItemError, [Row + 1]);
        InternalYamlProcessCollection(AYAML, AElements, Row, NextIndent, Remainer, AYesNoBool, AAllowDuplicateKeys);
        CurrRow := Row;
      end
      // An inline array, process it
      else if NextText.StartsWith('[') then
      begin
        InternalYamlProcessArray(AYAML, AElements, Row, NextIndent, Remainer, AYesNoBool, AAllowDuplicateKeys);
        CurrRow := Row;
      end
      // Indent, go in, recursive
      else if (Indent <> -1) and (NextIndent > Indent) then
      begin
        InternalYamlProcessElements(AYAML, AElements, Row, NextIndent, Remainer, AYesNoBool, AAllowDuplicateKeys);
        CurrRow := Row;
      end
      // Process this
      else
      begin
        // Get the key
        TokenType := InternalYamlReadToken(AYAML, Row, Indent, T, Remainer, Alias, Tag{%H-}, CollectionItem, IsLiteral, False);
        if Row >= 0 then
        begin
          CurrRow := Row;
          if (TokenType <> TYamlTokenType.tokenKey) then
            raise EYamlParsingException.CreateFmt(EYamlExpectedKeyError, [Row + 1]);
          Element.Key := T;
          Element.Tag := Tag;
          // Check for duplicated key?
          if (not AAllowDuplicateKeys) and (not T.Equals('<<')) then
          begin
            if KeysList.IndexOf(T) >= 0 then
              raise EYamlParsingException.CreateFmt(EYamlDuplicatedKeyError, [Row + 1]);
            Element.LineNumber := Row + 1;
            KeysList.Add(T);
          end;
          // Backup references
          PrevRow := Row;
          PrevIndent := Indent;
          PrevRemainer := Remainer;
          // Go for the value
          T := Remainer;
          TokenType := InternalYamlReadToken(AYAML, Row, Indent, T, Remainer, Alias, Tag, CollectionItem, IsLiteral, False);
          if Row >= 0 then
            CurrRow := Row;
          // EOF
          if Row < 0 then
          begin
            Element.Value := 'null';
            Done := True;
          end
          // An inline array is found
          else if T.StartsWith('[') then
          begin
            // Restore references
            Row := PrevRow;
            Indent := PrevIndent;
            Remainer := PrevRemainer;
          end
          // A collection item is found
          else if (CollectionItem > 0) or ((T.StartsWith('- ') or T.Equals('-')) and not IsLiteral) then
          begin
            if Row = PrevRow then
              raise EYamlParsingException.CreateFmt(EYamlCollectionItemError, [Row + 1]);
            // Restore references
            Row := PrevRow;
            Indent := PrevIndent;
            Remainer := PrevRemainer;
          end
          // A new key, is it outdent/error ?
          else if (TokenType = TYamlTokenType.tokenKey) then
          begin
            if Row = PrevRow then
              raise EYamlParsingException.CreateFmt(EYamlDoubleKeyError, [Row + 1]);
            if Indent <= PrevIndent then
              Element.Value := 'null';
            if Indent < PrevIndent then
              Done := True;
            // Restore references
            Row := PrevRow;
            Indent := PrevIndent;
            Remainer := PrevRemainer;
          end
          // A value
          else
          begin
            //                    if (T.IsEmpty) and (Indent <= PrevIndent) then
            //                      Element.Value := 'null'
            //                    else
            Element.Value := T;
            Element.Literal := IsLiteral;
            Element.Tag := Tag;
            if not Alias.IsEmpty then
            begin
              if Alias.StartsWith('*') then
                Element.Alias := Alias.Substring(1)
              else
              begin
                Element.Anchor := Alias.Substring(1);
                // Avoid duplicated anchor names
                if InternalYamlFindAnchor(AElements, Element.Anchor) >= 0 then
                  raise EYamlParsingException.CreateFmt(EYamlAnchorDuplicateError, [Row + 1]);
              end;
            end;
          end;
          if Element.Key.Equals('<<') and (Element.Alias.IsEmpty) then
            raise EYamlParsingException.CreateFmt(EYamlMergeInvalidError, [Row + 1]);
          Element.LineNumber := Row + 1;
          AElements.Add(Element);
          Element.Clear;
        end;
      end;
    end;

  finally
    if Assigned(KeysList) then
      FreeAndNil(KeysList)
  end;

  // Put in the closer
  Element.Indent := ElementIndent;
  Element.LineNumber := CurrRow + 1;
  Element.Value := '}';
  AElements.Add(Element);
  Element.Clear;

  ARow := CurrRow;
  AText := Remainer;
end;


// Format a YAML value to JSON
class function TYamlUtils.InternalYamlProcessJsonValue(AValue: AnsiString; ALiteral: Boolean; ATag: AnsiString; ALineNumber: Integer; AYesNoBool: Boolean): AnsiString;
var
  Value: AnsiString;
  Int: Int64;
  Float: Extended;
  Date: TDateTime;
  FormatSettings: TFormatSettings;
  ValueType: AnsiString;
begin
  FormatSettings.DecimalSeparator := '.';
  FormatSettings.ThousandSeparator := ',';
  FormatSettings.DateSeparator := '-';
  FormatSettings.TimeSeparator := ':';
  FormatSettings.ShortDateFormat := 'yyyy-mm-dd';
  FormatSettings.ShortTimeFormat := 'hh:nn:ss.z';
  FormatSettings.LongTimeFormat := 'hh:nn:ss.z';
  Value := AValue;
  if (not Value.IsEmpty) then
  begin
    // String tagged values are straight forward
    if (ATag = LTagStr) then
    begin
      ValueType := LTagStr;
      Value := '"' + Value + '"';
    end
    // Binary tagged values are also special
    else if (ATag = LTagBin) then
    begin
      ValueType := LTagBin;
      Value := Value;
    end
    else if (not ALiteral) and Value.ToLower.Equals('null') then
    begin
      ValueType := LTagNull;
      Value := 'null';
      if ATag = LTagMap then
      begin
        ValueType := LTagMap;
        Value := '{}';
      end
      else if ATag = LTagSeq then
      begin
        ValueType := LTagSeq;
        Value := '[]';
      end;
    end
    else if (not ALiteral) and Value.ToLower.Equals('true') then
    begin
      ValueType := LTagBool;
      Value := 'true';
    end
    else if (not ALiteral) and Value.ToLower.Equals('false') then
    begin
      ValueType := LTagBool;
      Value := 'false';
    end
    else if (not ALiteral) and (AYesNoBool) and Value.ToLower.Equals('yes') then
    begin
      ValueType := LTagBool;
      Value := 'true';
    end
    else if (not ALiteral) and (AYesNoBool) and Value.ToLower.Equals('no') then
    begin
      ValueType := LTagBool;
      Value := 'false';
    end
    else if (not ALiteral) and TryStrToInt64(Value.Trim, Int) then
    begin
      ValueType := LTagInt;
      Value := IntToStr(Int);
    end
    else if (not ALiteral) and TryStrToFloat(Value.Trim, Float, FormatSettings) then
    begin
      ValueType := LTagFloat;
      Value := FloatToStr(Float, FormatSettings);
    end
    else if (not ALiteral) and InternalTryStrToDateTime(Value.Trim, Date{%H-}, FormatSettings) then
    begin
      ValueType := LTagTime;
     {$IFNDEF PAS2JS}
      Value := '"' + DateToISO8601(Date, False) + '"';
     {$ELSE}
     // Function DateToRFC3339(ADate :TDateTime):string;
     LValue := '"'+DateToRFC3339(LDate)+'"';
     {$ENDIF}
    end
    else if ATag.StartsWith('!') and not ATag.StartsWith('!!') then begin
      ValueType := ATag;
      Value := '"' + Value + '"';
    end
    else
    begin
      ValueType := LTagStr;
      Value := '"' + Value + '"';
    end;
  end
  else
  begin
    if (ALiteral) or (ATag = '!!str') then
    begin
      ValueType := LTagStr;
      Value := '"' + Value + '"';
    end
    else if ATag = LTagMap then
      ValueType := LTagMap
    else if ATag = LTagSeq then
      ValueType := LTagSeq;
  end;
  // Check tag type (float will accept int as well)
  if (not ATag.IsEmpty) then
    if not ((ATag = LTagFloat) and (ValueType.Equals(LTagInt) or ValueType.Equals(LTagFloat))) then
      if not ValueType.Equals(ATag) then
        raise EYamlParsingException.CreateFmt(EYamlInvalidValueForTagError, [ALineNumber]);

  Result := Value;
end;


// Convert the prepared TYamlElements list to JSON
class procedure TYamlUtils.InternalYamlToJson(AElements: TYamlElements; AJSON: TStrings; AIndentation: TJsonIdentation; AYesNoBool: Boolean);
var
  i, j: Integer;
  Element: TYamlElement;
  NextElement: TYamlElement;
  PrevElement: TYamlElement;
  Displacement: Integer;
  Indent: Integer;
  Spaces: AnsiString;
  BinSpaces: AnsiString;
  Separator: AnsiString;
  Value: AnsiString;
  Bytes: Ansistring;
  Size: Integer;
begin
  Displacement := 0;
  AJSON.BeginUpdate;
  try
    AJSON.Clear;
    // Put it to json
    for i := 0 to AElements.Count - 1 do
    begin
      Separator := '';
      NextElement.Clear;
      PrevElement.Clear;
      Element := AElements[i];
      if i > 0 then
        PrevElement := AElements[i - 1];
      if i < AElements.Count - 1 then
        NextElement := AElements[i + 1];
      if (Element.Key.IsEmpty) and (Element.Value.Equals('[') or Element.Value.Equals('{')) then
      begin
        if (AJSON.Count = 0) then
        begin
          AJSON.Add(Element.Value);
          Inc(Displacement);
        end
        else
        begin
          Indent := (Element.Indent + Displacement - 1) * AIndentation;
          if Indent < 0 then
            Indent := 0;
          Spaces := String.Create(' ', Indent);
          if (PrevElement.Value = '[') or (AJSON[AJSON.Count - 1].EndsWith(',')) then
            AJSON.Add(Spaces + Element.Value)
          else
            AJSON[AJSON.Count - 1] := AJSON[AJSON.Count - 1] + ': ' + Element.Value;
        end;
      end
      else if (Element.Key.IsEmpty) and (Element.Value.Equals(']') or Element.Value.Equals('}')) then
      begin
        if (i = AElements.Count - 1) and (Displacement > 0) then
          Displacement := 0;
        Indent := (Element.Indent + Displacement - 1) * AIndentation;
        if Indent < 0 then
          Indent := 0;
        Spaces := String.Create(' ', Indent);
        if i < AElements.Count - 1 then
        begin
          if not (AElements[i + 1].Value.Equals('}') or AElements[i + 1].Value.Equals(']')) then
            Separator := ',';
        end;
        AJSON.Add(Spaces + Element.Value + Separator);
      end
      else
      begin
        Indent := (Element.Indent + Displacement) * AIndentation;
        Spaces := String.Create(' ', Indent);
        Value := InternalYamlProcessJsonValue(Element.Value, Element.Literal, Element.Tag, Element.LineNumber, AYesNoBool);
        // Check tag !!map special case
        if (Element.Tag = LTagMap) and (not Value.Equals('{}')) then
          if not (NextElement.Key.IsEmpty and NextElement.Value.Equals('{')) then
            raise EYamlParsingException.CreateFmt(EYamlInvalidValueForTagError, [Element.LineNumber]);
        // Check tag !!map special case
        if (Element.Tag = LTagSeq) and (not Value.Equals('[]')) then
          if not (NextElement.Key.IsEmpty and NextElement.Value.Equals('[')) then
            raise EYamlParsingException.CreateFmt(EYamlInvalidValueForTagError, [Element.LineNumber]);
        // Other cases
        if (NextElement.Indent >= Element.Indent) and (not Value.IsEmpty) and not (NextElement.Value.Equals('}') or NextElement.Value.Equals(']')) then
          Separator := ',';
        if Element.Key.IsEmpty then
          AJSON.Add(Spaces + Value + Separator)
        else
        begin
          // Check tag !!binary special case
          if Element.Tag = LTagBin then
          begin
            try
              try
                // WAS: Bytes := LBase64Decoder.DecodeStringToBytes(Value);
                Bytes := DecodeBase64(Value);
              except
                raise EYamlParsingException.CreateFmt(EYamlInvalidValueForTagError, [Element.LineNumber]);
              end;
              BinSpaces := String.Create(' ', Indent + AIndentation);
              Size := Length(Bytes);
              AJSON.Add(Spaces + '"' + Element.Key + '"' + ': ' + '[');
              for j := 1 to Size do
              begin
                if j < Size then
                  AJSON.Add(BinSpaces + IntToStr(Byte(Bytes[j])) + ',')
                else
                  AJSON.Add(BinSpaces + IntToStr(Byte(Bytes[j])));
              end;
              AJSON.Add(Spaces + ']' + Separator);
            finally
              SetLength(Bytes, 0);
            end;
          end
          else if Value.IsEmpty then
            AJSON.Add(Spaces + '"' + Element.Key + '"' + Separator)
          else
            AJSON.Add(Spaces + '"' + Element.Key + '"' + ': ' + Value + Separator);
        end;
      end;
    end;
  finally
    AJSON.EndUpdate;
  end;
end;


// Entry point to parse YAML to JSON
class procedure TYamlUtils.InternalYamlParse(AYAML, AJSON: TStrings; AIndentation: TJsonIdentation; AYesNoBool: Boolean; AAllowDuplicateKeys: Boolean);
var
  Elements: TYamlElements;
  Element: TYamlElement;
  TokenType: TYamlTokenType;
  Row: Integer;
  XRow: Integer;
  Indent: Integer;
  T: AnsiString;
  XT: AnsiString;
  Remainer: AnsiString;
  Alias: AnsiString;
  Tag: AnsiString;
  CollectionItem: Integer;
  IsLiteral: Boolean;
begin
  Row := -1;
  Indent := -1;
  XRow := -1;
  XT := '';
  Remainer := '';
  Alias := '';
  CollectionItem := 0;
  IsLiteral := False;

  // Read the first element to check what it is
  TokenType := InternalYamlReadToken(AYAML, XRow, Indent, XT, Remainer, Alias, Tag{%H-}, CollectionItem, IsLiteral, False);

  if (XRow >= 0) then
  begin

    // Reset variables
    Row := -1;
    Indent := -1;

    Elements := TYamlElements.Create;
    try

      // An inline array
      if XT.StartsWith('[') then
        InternalYamlProcessArray(AYAML, Elements, Row, Indent, T{%H-}, AYesNoBool, AAllowDuplicateKeys)
      // A collection
      else if (CollectionItem > 0) or ((XT.StartsWith('- ') or XT.Equals('-')) and (not IsLiteral)) then
        InternalYamlProcessCollection(AYAML, Elements, Row, Indent, T, AYesNoBool, AAllowDuplicateKeys)
      // Single text yaml
      else if TokenType = TYamlTokenType.tokenValue then
      begin
        Element.Value := XT;
        Element.Literal := IsLiteral;
        Element.LineNumber := XRow + 1;
        Element.Indent := 0;
        Element.Tag := Tag;
        Elements.Add(Element);
        Row := XRow;
      end
      // Key: value pairs
      else
      begin
        if XT.StartsWith('|') or XT.StartsWith('>') then
          raise EYamlParsingException.CreateFmt(EYamlInvalidBlockError, [XRow + 1]);
        InternalYamlProcessElements(AYAML, Elements, Row, Indent, T, AYesNoBool, AAllowDuplicateKeys);
      end;
      // Check if it's all consumed
      InternalYamlReadToken(AYAML, Row, Indent, T, Remainer, Alias, Tag, CollectionItem, IsLiteral, False);
      if not T.IsEmpty then
        raise EYamlParsingException.CreateFmt(EYamlUnconsumedContentError, [Row + 1]);
      // Process aliases/anchors (fisrt)
      InternalYamlResolveAliases(Elements);
      // Process merges (having aliases/anchors already resolved)
      InternalYamlResolveMerges(Elements);
      // Convert all to JSON
      InternalYamlToJson(Elements, AJSON, AIndentation, AYesNoBool);
    finally
      FreeAndNil(Elements)
    end;
  end;

end;

// JSON to YAML section
// --------------------

// Process JSON object to YAML (a touple)
class procedure TYamlUtils.InternalJsonObjToYaml(AJSON: TJsonNode; AOutStrings: TStrings; AIndentation: TYamlIdentation; var AIndent: Integer; AFromArray: Boolean = False; AYesNoBool: Boolean = False);
var
  i, j: Integer;
  Element: TJsonNode;
  Name: AnsiString;
  Value: TJsonNode;
  Spaces: AnsiString;
  Indent: Integer;
  Lines: TArray<String>;
begin
  Inc(AIndent);
  try
    for i := 0 to AJSON.Count - 1 do
    begin
      Indent := AIndent * AIndentation;
      if (AFromArray) and (i = 0) then
        Spaces := String.Create(' ', (AIndent - 1) * AIndentation) + '- '
      else
        Spaces := String.Create(' ', Indent);
      Element := AJSON.Child(i);
      Name := Element.Name;
      Value := Element;
      // Check for object type
      if (Value.Kind = nkObject) then
      begin
        if Value.Count = 0 then
          AOutStrings.Add(Spaces + Name + ': {}')
        else
        begin
          AOutStrings.Add(Spaces + Name + ':');
          InternalJsonObjToYaml(Value, AOutStrings, AIndentation, AIndent, False, AYesNoBool);
        end;
      end
      else if (Value.Kind = nkArray) then
      begin
        if Value.Count = 0 then
          AOutStrings.Add(Spaces + Name + ': []')
        else
        begin
          AOutStrings.Add(Spaces + Name + ':');
          InternalJsonArrToYaml(Value, AOutStrings, AIndentation, AIndent, False, AYesNoBool);
        end;
      end
      else
      begin
        Lines := InternalJsonValueToYaml(Value, Indent, AYesNoBool);
        try
          AOutStrings.Add(Spaces + Name + ': ' + Lines[0]);
          for j := 1 to High(Lines) do
            AOutStrings.Add(Spaces + Lines[j]);
        finally
          SetLength(Lines, 0);
          Lines := nil;
        end;
      end;
    end;
  finally
    Dec(AIndent);
  end;
end;


// Process JSON array to YAML
class procedure TYamlUtils.InternalJsonArrToYaml(AJSON: TJsonNode; AOutStrings: TStrings; AIndentation: TYamlIdentation; var AIndent: Integer; AFromArray: Boolean = False; AYesNoBool: Boolean = False);
var
  i, j: Integer;
  Value: TJsonNode;
  Spaces: AnsiString;
  Indent: Integer;
  Lines: TArray<String>;
begin
  Inc(AIndent);
  try
    for i := 0 to AJSON.Count - 1 do
    begin
      Indent := AIndent * AIndentation;
      if (AFromArray) and (i = 0) then
        Spaces := String.Create(' ', (AIndent - 1) * AIndentation) + '- '
      else
        Spaces := String.Create(' ', Indent);
      Value := AJSON.Child(i);
      // Check for object type
      if (Value.Kind = nkObject) then
      begin
        if Value.Count = 0 then
          AOutStrings.Add(Spaces + '- {}')
        else
          InternalJsonObjToYaml(Value, AOutStrings, AIndentation, AIndent, True, AYesNoBool);
      end
      // Check for array type
      else if (Value.Kind = nkArray) then
      begin
        if Value.Count = 0 then
          AOutStrings.Add(Spaces + '- []')
        else
          InternalJsonArrToYaml(Value, AOutStrings, AIndentation, AIndent, True, AYesNoBool);
      end
      else
      begin
        Lines := InternalJsonValueToYaml(Value, Indent, AYesNoBool);
        try
          AOutStrings.Add(Spaces + '- ' + Lines[0]);
          for j := 1 to High(Lines) do
            AOutStrings.Add(Spaces + Lines[j]);
        finally
          SetLength(Lines, 0);
          Lines := nil;
        end;
      end;
    end;
  finally
    Dec(AIndent);
  end;
end;


// Convert a value from JSON to YAML
class function TYamlUtils.InternalJsonValueToYaml(AJSON: TJsonNode; AIndent: Integer = 0; AYesNoBool: Boolean = False): TArray<String>;
const
  JsonLineFeed: AnsiString = chr(10);
var
  i: Integer;
  T: AnsiString;
  Float: Extended;
  Fold: AnsiString;
  Chomp: AnsiString;
  Spaces: AnsiString;
begin
  Fold := '';
  Chomp := '';
  Spaces := '';
  // TJSONValue is already "unescaped"
  T := AJSON.Value;
  if (AJSON.Kind = nkBool) then
  begin
    if AJSON.AsBoolean then
    begin
      if AYesNoBool then
        T := 'yes'
      else
        T := 'true';
    end
    else
    begin
      if AYesNoBool then
        T := 'no'
      else
        T := 'false';
    end;
  end
  else if (AJSON.Kind = nkNull) then
  begin
    T := '';
  end
  else if (AJSON.Kind = nkNumber) then
  begin
    Float := AJSON.AsNumber;
    if Frac(Float) = 0 then
      T := IntToStr(Trunc(Float))
    else
      // WWY: US-format setting was missing here
      T := FloatToStr(Float);
  end
  else if (AJSON.Kind = nkString) then
  begin
    if T.Trim.IsEmpty then
      T := ''''''
    else if T.Contains(JsonLineFeed) then // Process multilines ...
    begin
      // Have we empty lines at the begining ?
      if T.StartsWith(JsonLineFeed) then
        Fold := '>';
      // Have linefeed at the middle ?
      if T.Trim.Contains(JsonLineFeed) then
        Fold := '|';
      // Have more that one empty line at the end ?
      if T.EndsWith(JsonLineFeed + JsonLineFeed) then
        Chomp := '+'
      else if (not Fold.IsEmpty) and not (T.EndsWith(JsonLineFeed)) then
        Chomp := '-';
      // Recheck fold
      if not Chomp.IsEmpty and Fold.IsEmpty then
        Fold := '>';
      T := Fold + Chomp + JsonLineFeed + T;
      Result := T.Split([JsonLineFeed]);
      // Adjust identation
      if AIndent >= 0 then
      begin
        Spaces := String.Create(' ', AIndent + 1);
        for i := 1 to High(Result) do
          Result[i] := Spaces + Result[i];
      end;
    end;
  end;
  if Length(Result) = 0 then
  begin
    SetLength(Result, 1);
    Result[0] := T;
  end;
end;


// THE PUBLIC section
// ------------------

// JSON TO YAML
class function TYamlUtils.JsonToYaml(AJSON: AnsiString; AIndentation: TYamlIdentation = 2; AYesNoBool: Boolean = False): AnsiString;
var
  Node: TJsonNode;
begin
  Result := '';
  Node := TJsonNode.Create;
  try
    if Node.TryParse(AJSON) then
      Result := JsonToYaml(Node, AIndentation, AYesNoBool);
  finally
    FreeAndNil(Node);
  end;
end;


class function TYamlUtils.JsonToYaml(AJSON: TJsonNode; AIndentation: TYamlIdentation = 2; AYesNoBool: Boolean = False): AnsiString;
var
  Lines: TStringList;
begin
  Lines := TStringList.Create;
  try
    JsonToYaml(AJSON, Lines, AIndentation, AYesNoBool);
    Result := Lines.Text;
  finally
    Lines.Free;
  end;
end;


class procedure TYamlUtils.JsonToYaml(AJSON: TStrings; AOutStrings: TStrings; AIndentation: TYamlIdentation; AYesNoBool: Boolean);
var
  Node: TJsonNode;
begin
  Node := TJsonNode.Create;
  try
    if Node.TryParse(AJSON.Text) then
      JsonToYaml(Node, AOutStrings, AIndentation, AYesNoBool);
  finally
    FreeAndNil(Node);
  end;
end;


class procedure TYamlUtils.JsonToYaml(AJSON: TJsonNode; AOutStrings: TStrings; AIndentation: TYamlIdentation; AYesNoBool: Boolean);
var
  i: Integer;
  Indent: Integer;
  Lines: TArray<String>;
begin
  Indent := -1;
  AOutStrings.BeginUpdate;
  try
    AOutStrings.Clear;
    if (AJSON.Kind = nkObject) then
      InternalJsonObjToYaml(AJSON, AOutStrings, AIndentation, Indent, False, AYesNoBool)
    else if (AJSON.Kind = nkArray) then
      InternalJsonArrToYaml(AJSON, AOutStrings, AIndentation, Indent, False, AYesNoBool)
    else
    begin
      Lines := InternalJsonValueToYaml(AJSON, -1, AYesNoBool);
      try
        AOutStrings.Add(Lines[0]);
        for i := 1 to High(Lines) do
          AOutStrings.Add(Lines[i]);
      finally
        SetLength(Lines, 0);
        Lines := nil;
      end;
    end;
  finally
    AOutStrings.EndUpdate;
  end;
end;


// YAML TO JSON
class procedure TYamlUtils.YamlToJson(AYAML: TStrings; AOutStrings: TStrings; AIndentation: TJsonIdentation = 2; AYesNoBool: Boolean = True; AAllowDuplicateKeys: Boolean = True);
begin
  InternalYamlParse(AYAML, AOutStrings, AIndentation, AYesNoBool, AAllowDuplicateKeys);
end;


class function TYamlUtils.YamlToJson(AYAML: TStrings; AIndentation: TJsonIdentation = 2; AYesNoBool: Boolean = True; AAllowDuplicateKeys: Boolean = True): AnsiString;
var
  Lines: TStringList;
begin
  Lines := TStringList.Create;
  try
    YamlToJson(AYAML, Lines, AIndentation, AYesNoBool, AAllowDuplicateKeys);
    Result := Lines.Text;
  finally
    Lines.Free;
  end;
end;


class function TYamlUtils.YamlToJson(AYAML: AnsiString; AIndentation: TJsonIdentation = 2; AYesNoBool: Boolean = True; AAllowDuplicateKeys: Boolean = True): AnsiString;
var
  Lines: TStringList;
begin
  Lines := TStringList.Create;
  try
    Lines.Text := AYAML;
    Result := YamlToJson(Lines, AIndentation, AYesNoBool, AAllowDuplicateKeys);
  finally
    Lines.Free;
  end;
end;


class function TYamlUtils.YamlToJsonValue(AYAML: AnsiString; AIndentation: TJsonIdentation = 0; AYesNoBool: Boolean = True; AAllowDuplicateKeys: Boolean = True): TJsonNode;
var
  Lines: TStringList;
begin
  Lines := TStringList.Create;
  try
    Lines.Text := AYAML;
    Result := YamlToJsonValue(Lines, AIndentation, AYesNoBool, AAllowDuplicateKeys);
  finally
    Lines.Free;
  end;
end;


class function TYamlUtils.YamlToJsonValue(AYAML: TStrings; AIndentation: TJsonIdentation = 0; AYesNoBool: Boolean = True; AAllowDuplicateKeys: Boolean = True): TJsonNode;
var
  JSON: AnsiString;
begin
  JSON := YamlToJson(AYAML, AIndentation, AYesNoBool, AAllowDuplicateKeys);
  Result := TJsonNode.Create;
  Result.Parse(JSON);
end;

class function TYamlUtils.JsonMinify(AJSON: AnsiString): AnsiString;
var
  Lines: TStringList;
begin
  Lines := TStringList.Create;
  try
    Lines.Text := AJSON;
    Result := JSonMinify(Lines);
  finally
    FreeAndNil(Lines);
  end;
end;


class function TYamlUtils.JsonMinify(AJSON: TStrings): AnsiString;
var
  i: Integer;
begin
  Result := '';
  for i := 0 to AJSON.Count - 1 do
  begin
    if Result.IsEmpty then
      Result := Result + AJSON[i].Trim
    else
      Result := Result + ' ' + AJSON[i].Trim;
  end;
end;

end.
