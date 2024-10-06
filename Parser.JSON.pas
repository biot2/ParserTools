{==============================================================================|
| Project : JSON/YAML Parser Tools for Object Pascal                           |
|==============================================================================|
| Content: JSON parser/serializer tools                                        |
|==============================================================================|
| Copyright (c) 2024, Vahid Nasehi Oskouei                                     |
| All rights reserved.                                                         |
|                                                                              |
| License: MIT License                                                         |
|                                                                              |
| Remastered and rewritten version originally based on a work by:              |
|   Json Tools Pascal Unit                                                     |
|   A small json parser with no dependencies                                   |
|   http://www.getlazarus.org/json                                             |
|                                                                              |
| Project download homepage:                                                   |
|   https://github.com/biot2/ParserTools                                       |
|                                                                              |
| History:                                                                     |
|   2024-10-05                                                                 |
|   - Support both Delphi and Free Pascal                                      |
|   - Forced utf-8 (AnsiString) unicode support                                |
|                                                                              |
|==============================================================================}

unit Parser.JSON;

{$IFDEF FPC}
  {$MODE Delphi}
{$ENDIF}


interface

uses
  Classes, SysUtils;

{ EJSONException is the exception type used by TJSONNode. It is thrown
  during parse if the string is invalid json or if an attempt is made to
  access a non collection by name or index. }

type
  EJSONException = class(Exception);

{ TJSONNodeKind is 1 of 6 possible values described below }

  TJSONNodeKind = (
    { Object such as { }
    nkObject,
    { Array such as [ ] }
    nkArray,
    { The literal values true or false }
    nkBool,
    { The literal value null }
    nkNull,
    { A number value such as 123, 1.23e2, or -1.5 }
    nkNumber,
    { A string such as "hello\nworld!" }
    nkString);

  TJSONNode = class;

{ TJSONNodeEnumerator is used to enumerate 'for ... in' statements }

  TJSONNodeEnumerator = record
  private
    FNode: TJSONNode;
    FIndex: Integer;
  public
    procedure Init(Node: TJSONNode);
    function GetCurrent: TJSONNode;
    function MoveNext: Boolean;
    property Current: TJSONNode read GetCurrent;
  end;

{ TJSONNode is the class used to parse, build, and navigate a json document.
  You should only create and free the root node of your document. The root
  node will manage the lifetime of all children through methods such as Add,
  Delete, and Clear.

  When you create a TJSONNode node it will have no parent and is considered to
  be the root node. The root node must be either an array or an object. Attempts
  to convert a root to anything other than array or object will raise an
  exception.

  Note: The parser supports unicode by converting unicode characters escaped as
  values such as \u20AC. If your json string has an escaped unicode character it
  will be unescaped when converted to a pascal string.

  See also:

  JsonStringDecode to convert a JSON string to a normal string
  JsonStringEncode to convert a normal string to a JSON string }

  TJSONNode = class
  private
    FStack: Integer;
    FParent: TJSONNode;
    FName: AnsiString;
    FKind: TJSONNodeKind;
    FValue: AnsiString;
    FList: TList;
    procedure ParseObject(Node: TJSONNode; var C: PChar);
    procedure ParseArray(Node: TJSONNode; var C: PChar);
    procedure Error(const Msg: AnsiString = '');
    function Format(const Indent: AnsiString): AnsiString;
    function FormatCompact: AnsiString;
    function Add(Kind: TJSONNodeKind; const Name, Value: AnsiString): TJSONNode; overload;
    function GetRoot: TJSONNode;
    procedure SetKind(Value: TJSONNodeKind);
    function GetName: AnsiString;
    procedure SetName(const Value: AnsiString);
    function GetValue: AnsiString;
    function GetCount: Integer;
    function GetAsJson: AnsiString;
    function GetAsArray: TJSONNode;
    function GetAsObject: TJSONNode;
    function GetAsNull: TJSONNode;
    function GetAsBoolean: Boolean;
    procedure SetAsBoolean(Value: Boolean);
    function GetAsString: AnsiString;
    procedure SetAsString(const Value: AnsiString);
    function GetAsNumber: Double;
    procedure SetAsNumber(Value: Double);
  public
    { A parent node owns all children. Only destroy a node if it has no parent.
      To destroy a child node use Delete or Clear methods instead. }
    destructor Destroy; override;
    { GetEnumerator adds 'for ... in' statement support }
    function GetEnumerator: TJSONNodeEnumerator;
    { Loading and saving methods }
    procedure LoadFromStream(Stream: TStream);
    procedure SaveToStream(Stream: TStream);
    procedure LoadFromFile(const FileName: AnsiString);
    procedure SaveToFile(const FileName: AnsiString);
    { Convert a json string into a value or a collection of nodes. If the
      current node is root then the json must be an array or object. }
    procedure Parse(const Json: AnsiString);
    { The same as Parse, but returns true if no exception is caught }
    function TryParse(const Json: AnsiString): Boolean;
    { Add a child node by node kind. If the current node is an array then the
      name parameter will be discarded. If the current node is not an array or
      object the Add methods will convert the node to an object and discard
      its current value.

      Note: If the current node is an object then adding an existing name will
      overwrite the matching child node instead of adding. }
    function Add(const Name: AnsiString; K: TJSONNodeKind = nkObject): TJSONNode; overload;
    function Add(const Name: AnsiString; B: Boolean): TJSONNode; overload;
    function Add(const Name: AnsiString; const N: Double): TJSONNode; overload;
    function Add(const Name: AnsiString; const S: AnsiString): TJSONNode; overload;
    { Convert to an array and add an item }
    function Add: TJSONNode; overload;
    { Delete a child node by index or name }
    procedure Delete(Index: Integer); overload;
    procedure Delete(const Name: AnsiString); overload;
    { Remove all child nodes }
    procedure Clear;
    { Get a child node by index. EJSONException is raised if node is not an
      array or object or if the index is out of bounds.

      See also: Count }
    function Child(Index: Integer): TJSONNode; overload;
    { Get a child node by name. If no node is found nil will be returned. }
    function Child(const Name: AnsiString): TJSONNode; overload;
    { Search for a node using a path string and return true if exists }
    function Exists(const Path: AnsiString): Boolean;
    { Search for a node using a path string }
    function Find(const Path: AnsiString): TJSONNode; overload;
    { Search for a node using a path string and return true if exists }
    function Find(const Path: AnsiString; out Node: TJSONNode): Boolean; overload;
    { Force a series of nodes to exist and return the end node }
    function Force(const Path: AnsiString): TJSONNode;
    { Format the node and all its children as json }
    function ToString: AnsiString; override;
    { Root node is read only. A node the root when it has no parent. }
    property Root: TJSONNode read GetRoot;
    { Parent node is read only }
    property Parent: TJSONNode read FParent;
    { Kind can also be changed using the As methods.

      Note: Changes to Kind cause Value to be reset to a default value. }
    property Kind: TJSONNodeKind read FKind write SetKind;
    { Name is unique within the scope }
    property Name: AnsiString read GetName write SetName;
    { Value of the node in json e.g. '[]', '"hello\nworld!"', 'true', or '1.23e2' }
    property Value: AnsiString read GetValue write Parse;
    { The number of child nodes. If node is not an object or array this
      property will return 0. }
    property Count: Integer read GetCount;
    { AsJson is the more efficient version of Value. Text returned from AsJson
      is the most compact representation of the node in json form.

      Note: If you are writing a services to transmit or receive json data then
      use AsJson. If you want friendly human readable text use Value. }
    property AsJson: AnsiString read GetAsJson write Parse;
    { Convert the node to an array }
    property AsArray: TJSONNode read GetAsArray;
    { Convert the node to an object }
    property AsObject: TJSONNode read GetAsObject;
    { Convert the node to null }
    property AsNull: TJSONNode read GetAsNull;
    { Convert the node to a bool }
    property AsBoolean: Boolean read GetAsBoolean write SetAsBoolean;
    { Convert the node to a string }
    property AsString: AnsiString read GetAsString write SetAsString;
    { Convert the node to a number }
    property AsNumber: Double read GetAsNumber write SetAsNumber;
  end;

{ JsonValidate tests if a string contains a valid json format }
function JsonValidate(const Json: AnsiString): Boolean;
{ JsonNumberValidate tests if a string contains a valid json formatted number }
function JsonNumberValidate(const N: AnsiString): Boolean;
{ JsonStringValidate tests if a string contains a valid json formatted string }
function JsonStringValidate(const S: AnsiString): Boolean;
{ JsonStringEncode converts a pascal string to a json string }
function JsonStringEncode(const S: AnsiString): AnsiString;
{ JsonStringEncode converts a json string to a pascal string }
function JsonStringDecode(const S: AnsiString): AnsiString;
{ JsonToXml converts a json string to xml }
function JsonToXml(const S: AnsiString): AnsiString;

implementation

resourcestring
  SNodeNotCollection = 'Node is not a container';
  SRootNodeKind = 'Root node must be an array or object';
  SIndexOutOfBounds = 'Index out of bounds';
  SParsingError = 'Error while parsing text';

type
  TJSONTokenKind = (tkEnd, tkError, tkObjectOpen, tkObjectClose, tkArrayOpen,
    tkArrayClose, tkColon, tkComma, tkNull, tkFalse, tkTrue, tkString, tkNumber);

  TJSONToken = record
    Head: PChar;
    Tail: PChar;
    Kind: TJSONTokenKind;
    function Value: AnsiString;
  end;

const
  Hex = ['0'..'9', 'A'..'F', 'a'..'f'];

function TJSONToken.Value: AnsiString;
begin
  case Kind of
    tkEnd: Result := #0;
    tkError: Result := #0;
    tkObjectOpen: Result := '{';
    tkObjectClose: Result := '}';
    tkArrayOpen: Result := '[';
    tkArrayClose: Result := ']';
    tkColon: Result := ':';
    tkComma: Result := ',';
    tkNull: Result := 'null';
    tkFalse: Result := 'false';
    tkTrue: Result := 'true';
  else
    SetString(Result, Head, Tail - Head);
  end;
end;

function NextToken(var C: PChar; out T: TJSONToken): Boolean;
begin
  if C^ > #0 then
    if C^ <= ' ' then
    repeat
      Inc(C);
      if C^ = #0 then
        Break;
    until C^ > ' ';
  T.Head := C;
  T.Tail := C;
  T.Kind := tkEnd;
  if C^ = #0 then
    Exit(False);
  if C^ = '{' then
  begin
    Inc(C);
    T.Tail := C;
    T.Kind := tkObjectOpen;
    Exit(True);
  end;
  if C^ = '}' then
  begin
    Inc(C);
    T.Tail := C;
    T.Kind := tkObjectClose;
    Exit(True);
  end;
  if C^ = '[' then
  begin
    Inc(C);
    T.Tail := C;
    T.Kind := tkArrayOpen;
    Exit(True);
  end;
  if C^ = ']' then
  begin
    Inc(C);
    T.Tail := C;
    T.Kind := tkArrayClose;
    Exit(True);
  end;
  if C^ = ':' then
  begin
    Inc(C);
    T.Tail := C;
    T.Kind := tkColon;
    Exit(True);
  end;
  if C^ = ',' then
  begin
    Inc(C);
    T.Tail := C;
    T.Kind := tkComma;
    Exit(True);
  end;
  if (C[0] = 'n') and (C[1] = 'u') and (C[2] = 'l') and (C[3] = 'l')  then
  begin
    Inc(C, 4);
    T.Tail := C;
    T.Kind := tkNull;
    Exit(True);
  end;
  if (C[0] = 'f') and (C[1] = 'a') and (C[2] = 'l') and (C[3] = 's') and (C[4] = 'e')  then
  begin
    Inc(C, 5);
    T.Tail := C;
    T.Kind := tkFalse;
    Exit(True);
  end;
  if (C[0] = 't') and (C[1] = 'r') and (C[2] = 'u') and (C[3] = 'e')  then
  begin
    Inc(C, 4);
    T.Tail := C;
    T.Kind := tkTrue;
    Exit(True);
  end;
  if C^ = '"'  then
  begin
    repeat
      Inc(C);
      if C^ = '\' then
      begin
        Inc(C);
        if C^ < ' ' then
        begin
          T.Tail := C;
          T.Kind := tkError;
          Exit(False);
        end;
        if C^ = 'u' then
          if not ((C[1] in Hex) and (C[2] in Hex) and (C[3] in Hex) and (C[4] in Hex)) then
          begin
            T.Tail := C;
            T.Kind := tkError;
            Exit(False);
          end;
      end
      else if C^ = '"' then
      begin
        Inc(C);
        T.Tail := C;
        T.Kind := tkString;
        Exit(True);
      end;
    until C^ in [#0, #10, #13];
    T.Tail := C;
    T.Kind := tkError;
    Exit(False);
  end;
  if C^ in ['-', '0'..'9'] then
  begin
    if C^ = '-' then
      Inc(C);
    if C^ in ['0'..'9'] then
    begin
      while C^ in ['0'..'9'] do
        Inc(C);
      if C^ = '.' then
      begin
        Inc(C);
        if C^ in ['0'..'9'] then
        begin
          while C^ in ['0'..'9'] do
            Inc(C);
        end
        else
        begin
          T.Tail := C;
          T.Kind := tkError;
          Exit(False);
        end;
      end;
      if C^ in ['E', 'e'] then
      begin
        Inc(C);
        if C^ = '+' then
          Inc(C)
        else if C^ = '-' then
          Inc(C);
        if C^ in ['0'..'9'] then
        begin
          while C^ in ['0'..'9'] do
            Inc(C);
        end
        else
        begin
          T.Tail := C;
          T.Kind := tkError;
          Exit(False);
        end;
      end;
      T.Tail := C;
      T.Kind := tkNumber;
      Exit(True);
    end;
  end;
  T.Kind := tkError;
  Result := False;
end;

{ TJSONNodeEnumerator }

procedure TJSONNodeEnumerator.Init(Node: TJSONNode);
begin
  FNode := Node;
  FIndex := -1;
end;

function TJSONNodeEnumerator.GetCurrent: TJSONNode;
begin
  if FNode.FList = nil then
    Result := nil
  else if FIndex < 0 then
    Result := nil
  else if FIndex < FNode.FList.Count then
    Result := TJSONNode(FNode.FList[FIndex])
  else
    Result := nil;
end;

function TJSONNodeEnumerator.MoveNext: Boolean;
begin
  Inc(FIndex);
  if FNode.FList = nil then
    Result := False
  else
    Result := FIndex < FNode.FList.Count;
end;

{ TJSONNode }

destructor TJSONNode.Destroy;
begin
  Clear;
  inherited Destroy;
end;

function TJSONNode.GetEnumerator: TJSONNodeEnumerator;
begin
  Result.Init(Self);
end;

procedure TJSONNode.LoadFromStream(Stream: TStream);
var
  S: AnsiString;
  i: Int64;
begin
  i := Stream.Size - Stream.Position;
  S := '';
  SetLength(S, i);
  Stream.Read(PChar(S)^, i);
  Parse(S);
end;

procedure TJSONNode.SaveToStream(Stream: TStream);
var
  S: AnsiString;
  i: Int64;
begin
  S := Value;
  i := Length(S);
  Stream.Write(PChar(S)^, i);
end;

procedure TJSONNode.LoadFromFile(const FileName: AnsiString);
var
  F: TFileStream;
begin
  F := TFileStream.Create(FileName, fmOpenRead);
  try
    LoadFromStream(F);
  finally
    F.Free;
  end;
end;

procedure TJSONNode.SaveToFile(const FileName: AnsiString);
var
  F: TFileStream;
begin
  F := TFileStream.Create(FileName, fmCreate);
  try
    SaveToStream(F);
  finally
    F.Free;
  end;
end;

const
  MaxStack = 1000;

procedure TJSONNode.ParseObject(Node: TJSONNode; var C: PChar);
var
  T: TJSONToken;
  N: AnsiString;
begin
  Inc(FStack);
  if FStack > MaxStack then
    Error;
  while NextToken(C, T) do
  begin
    case T.Kind of
      tkString: N := JsonStringDecode(T.Value);
      tkObjectClose:
        begin
          Dec(FStack);
          Exit;
        end
    else
      Error;
    end;
    NextToken(C, T);
    if T.Kind <> tkColon then
      Error;
    NextToken(C, T);
    case T.Kind of
      tkObjectOpen: ParseObject(Node.Add(nkObject, N, ''), C);
      tkArrayOpen: ParseArray(Node.Add(nkArray, N, ''), C);
      tkNull: Node.Add(nkNull, N, 'null');
      tkFalse: Node.Add(nkBool, N, 'false');
      tkTrue: Node.Add(nkBool, N, 'true');
      tkString: Node.Add(nkString, N, T.Value);
      tkNumber: Node.Add(nkNumber, N, T.Value);
    else
      Error;
    end;
    NextToken(C, T);
    if T.Kind = tkComma then
      Continue;
    if T.Kind = tkObjectClose then
    begin
      Dec(FStack);
      Exit;
    end;
    Error;
  end;
  Error;
end;

procedure TJSONNode.ParseArray(Node: TJSONNode; var C: PChar);
var
  T: TJSONToken;
begin
  Inc(FStack);
  if FStack > MaxStack then
    Error;
  while NextToken(C, T) do
  begin
    case T.Kind of
      tkObjectOpen: ParseObject(Node.Add(nkObject, '', ''), C);
      tkArrayOpen: ParseArray(Node.Add(nkArray, '', ''), C);
      tkNull: Node.Add(nkNull, '', 'null');
      tkFalse: Node.Add(nkBool, '', 'false');
      tkTrue: Node.Add(nkBool, '', 'true');
      tkString: Node.Add(nkString, '', T.Value);
      tkNumber: Node.Add(nkNumber, '', T.Value);
      tkArrayClose:
        begin
          Dec(FStack);
          Exit;
        end
    else
      Error;
    end;
    NextToken(C, T);
    if T.Kind = tkComma then
      Continue;
    if T.Kind = tkArrayClose then
    begin
      Dec(FStack);
      Exit;
    end;
    Error;
  end;
  Error;
end;

procedure TJSONNode.Parse(const Json: AnsiString);
var
  C: PChar;
  T: TJSONToken;
begin
  Clear;
  C := PChar(Json);
  if FParent = nil then
  begin
    if NextToken(C, T) and (T.Kind in [tkObjectOpen, tkArrayOpen]) then
    begin
      try
        if T.Kind = tkObjectOpen then
        begin
          FKind := nkObject;
          ParseObject(Self, C);
        end
        else
        begin
          FKind := nkArray;
          ParseArray(Self, C);
        end;
        NextToken(C, T);
        if T.Kind <> tkEnd then
          Error;
      except
        Clear;
        raise;
      end;
    end
    else
      Error(SRootNodeKind);
  end
  else
  begin
    NextToken(C, T);
    case T.Kind of
      tkObjectOpen:
        begin
          FKind := nkObject;
          ParseObject(Self, C);
        end;
      tkArrayOpen:
        begin
          FKind := nkArray;
          ParseArray(Self, C);
        end;
      tkNull:
        begin
          FKind := nkNull;
          FValue := 'null';
        end;
      tkFalse:
        begin
          FKind := nkBool;
          FValue := 'false';
        end;
      tkTrue:
        begin
          FKind := nkBool;
          FValue := 'true';
        end;
      tkString:
        begin
          FKind := nkString;
          FValue := T.Value;
        end;
      tkNumber:
        begin
          FKind := nkNumber;
          FValue := T.Value;
        end;
    else
      Error;
    end;
    NextToken(C, T);
    if T.Kind <> tkEnd then
    begin
      Clear;
      Error;
    end;
  end;
end;

function TJSONNode.TryParse(const Json: AnsiString): Boolean;
begin
  try
    Parse(Json);
    Result := True;
  except
    Result := False;
  end;
end;

procedure TJSONNode.Error(const Msg: AnsiString = '');
begin
  FStack := 0;
  if Msg = '' then
    raise EJSONException.Create(SParsingError)
  else
    raise EJSONException.Create(Msg);
end;

function TJSONNode.GetRoot: TJSONNode;
begin
  Result := Self;
  while Result.FParent <> nil do
    Result := Result.FParent;
end;

procedure TJSONNode.SetKind(Value: TJSONNodeKind);
begin
  if Value = FKind then Exit;
  case Value of
    nkObject: AsObject;
    nkArray: AsArray;
    nkBool: AsBoolean;
    nkNull: AsNull;
    nkNumber: AsNumber;
    nkString: AsString;
  end;
end;

function TJSONNode.GetName: AnsiString;
begin
  if FParent = nil then
    Exit('0');
  if FParent.FKind = nkArray then
    Result := IntToStr(FParent.FList.IndexOf(Self))
  else
    Result := FName;
end;

procedure TJSONNode.SetName(const Value: AnsiString);
var
  N: TJSONNode;
begin
  if FParent = nil then
    Exit;
  if FParent.FKind = nkArray then
    Exit;
  N := FParent.Child(Value);
  if N = Self then
    Exit;
  FParent.FList.Remove(N);
  FName := Value;
end;

function TJSONNode.GetValue: AnsiString;
begin
  if FKind in [nkObject, nkArray] then
    Result := Format('')
  else
    Result := FValue;
end;

function TJSONNode.GetAsJson: AnsiString;
begin
  if FKind in [nkObject, nkArray] then
    Result := FormatCompact
  else
    Result := FValue;
end;

function TJSONNode.GetAsArray: TJSONNode;
begin
  if FKind <> nkArray then
  begin
    Clear;
    FKind := nkArray;
    FValue := '';
  end;
  Result := Self;
end;

function TJSONNode.GetAsObject: TJSONNode;
begin
  if FKind <> nkObject then
  begin
    Clear;
    FKind := nkObject;
    FValue := '';
  end;
  Result := Self;
end;

function TJSONNode.GetAsNull: TJSONNode;
begin
  if FParent = nil then
    Error(SRootNodeKind);
  if FKind <> nkNull then
  begin
    Clear;
    FKind := nkNull;
    FValue := 'null';
  end;
  Result := Self;
end;

function TJSONNode.GetAsBoolean: Boolean;
begin
  if FParent = nil then
    Error(SRootNodeKind);
  if FKind <> nkBool then
  begin
    Clear;
    FKind := nkBool;
    FValue := 'false';
    Exit(False);
  end;
  Result := FValue = 'true';
end;

procedure TJSONNode.SetAsBoolean(Value: Boolean);
begin
  if FParent = nil then
    Error(SRootNodeKind);
  if FKind <> nkBool then
  begin
    Clear;
    FKind := nkBool;
  end;
  if Value then
    FValue := 'true'
  else
    FValue := 'false';
end;

function TJSONNode.GetAsString: AnsiString;
begin
  if FParent = nil then
    Error(SRootNodeKind);
  if FKind <> nkString then
  begin
    Clear;
    FKind := nkString;
    FValue := '""';
    Exit('');
  end;
  Result := JsonStringDecode(FValue);
end;

procedure TJSONNode.SetAsString(const Value: AnsiString);
begin
  if FParent = nil then
    Error(SRootNodeKind);
  if FKind <> nkString then
  begin
    Clear;
    FKind := nkString;
  end;
  FValue := JsonStringEncode(Value);
end;

function TJSONNode.GetAsNumber: Double;
begin
  if FParent = nil then
    Error(SRootNodeKind);
  if FKind <> nkNumber then
  begin
    Clear;
    FKind := nkNumber;
    FValue := '0';
    Exit(0);
  end;
  Result := StrToFloatDef(FValue, 0);
end;

procedure TJSONNode.SetAsNumber(Value: Double);
begin
  if FParent = nil then
    Error(SRootNodeKind);
  if FKind <> nkNumber then
  begin
    Clear;
    FKind := nkNumber;
  end;
  FValue := FloatToStr(Value);
end;

function TJSONNode.Add: TJSONNode;
begin
  Result := AsArray.Add('');
end;

function TJSONNode.Add(Kind: TJSONNodeKind; const Name, Value: AnsiString): TJSONNode;
var
  S: AnsiString;
begin
  if not (FKind in [nkArray, nkObject]) then
    if Name = '' then
      AsArray
    else
      AsObject;
  if FKind in [nkArray, nkObject] then
  begin
    if FList = nil then
      FList := TList.Create;
    if FKind = nkArray then
      S := IntToStr(FList.Count)
    else
      S := Name;
    Result := Child(S);
    if Result = nil then
    begin
      Result := TJSONNode.Create;
      Result.FName := S;
      FList.Add(Result);
    end;
    if Kind = nkNull then
      Result.FValue := 'null'
    else if Kind in [nkBool, nkString, nkNumber] then
      Result.FValue := Value
    else
    begin
      Result.FValue := '';
      Result.Clear;
    end;
    Result.FParent := Self;
    Result.FKind := Kind;
  end
  else
    Error(SNodeNotCollection);
end;

function TJSONNode.Add(const Name: AnsiString; K: TJSONNodeKind = nkObject): TJSONNode; overload;
begin
  case K of
    nkObject, nkArray: Result := Add(K, Name, '');
    nkNull: Result := Add(K, Name, 'null');
    nkBool: Result := Add(K, Name, 'false');
    nkNumber: Result := Add(K, Name, '0');
    nkString: Result := Add(K, Name, '""');
  end;
end;

function TJSONNode.Add(const Name: AnsiString; B: Boolean): TJSONNode; overload;
const
  Bools: array[Boolean] of AnsiString = ('false', 'true');
begin
  Result := Add(nkBool, Name, Bools[B]);
end;

function TJSONNode.Add(const Name: AnsiString; const N: Double): TJSONNode; overload;
begin
  Result := Add(nkNumber, Name, FloatToStr(N));
end;

function TJSONNode.Add(const Name: AnsiString; const S: AnsiString): TJSONNode; overload;
begin
  Result := Add(nkString, Name, JsonStringEncode(S));
end;

procedure TJSONNode.Delete(Index: Integer);
var
  N: TJSONNode;
begin
  N := Child(Index);
  if N <> nil then
  begin
    N.Free;
    FList.Delete(Index);
    if FList.Count = 0 then
    begin
      FList.Free;
      FList := nil;
    end;
  end;
end;

procedure TJSONNode.Delete(const Name: AnsiString);
var
  N: TJSONNode;
begin
  N := Child(Name);
  if N <> nil then
  begin
    N.Free;
    FList.Remove(N);
    if FList.Count = 0 then
    begin
      FList.Free;
      FList := nil;
    end;
  end;
end;

procedure TJSONNode.Clear;
var
  i: Integer;
begin
  if FList <> nil then
  begin
    for i := 0 to FList.Count - 1 do
      TObject(FList[i]).Free;
    FList.Free;
    FList := nil;
  end;
end;

function TJSONNode.Child(Index: Integer): TJSONNode;
begin
  if FKind in [nkArray, nkObject] then
  begin
    if FList = nil then
      Error(SIndexOutOfBounds);
    if (Index < 0) or (Index > FList.Count - 1) then
      Error(SIndexOutOfBounds);
    Result := TJSONNode(FList[Index]);
  end
  else
    Error(SNodeNotCollection);
end;

function TJSONNode.Child(const Name: AnsiString): TJSONNode;
var
  N: TJSONNode;
  i: Integer;
begin
  Result := nil;
  if (FList <> nil) and (FKind in [nkArray, nkObject]) then
    if FKind = nkArray then
    begin
      i := StrToIntDef(Name, -1);
      if (i > -1) and (i < FList.Count) then
        Exit(TJSONNode(FList[i]));
    end
    else for i := 0 to FList.Count - 1 do
    begin
      N := TJSONNode(FList[i]);
      if N.FName = Name then
        Exit(N);
    end;
end;

function TJSONNode.Exists(const Path: AnsiString): Boolean;
begin
  Result := Find(Path) <> nil;
end;

function TJSONNode.Find(const Path: AnsiString): TJSONNode;
var
  N: TJSONNode;
  A, B: PChar;
  S: AnsiString;
begin
  Result := nil;
  if Path = '' then
    Exit(Child(''));
  if Path[1] = '/' then
  begin
    N := Self;
    while N.Parent <> nil do
      N := N.Parent;
  end
  else
    N := Self;
  A := PChar(Path);
  if A^ = '/' then
  begin
    Inc(A);
    if A^ = #0 then
      Exit(N);
  end;
  if A^ = #0 then
    Exit(N.Child(''));
  B := A;
  while B^ > #0 do
  begin
    if B^ = '/' then
    begin
      SetString(S, A, B - A);
      N := N.Child(S);
      if N = nil then
        Exit(nil);
      A := B + 1;
      B := A;
    end
    else
    begin
      Inc(B);
      if B^ = #0 then
      begin
        SetString(S, A, B - A);
        N := N.Child(S);
      end;
    end;
  end;
  Result := N;
end;

function TJSONNode.Find(const Path: AnsiString; out Node: TJSONNode): Boolean;
begin
  Node := Find(Path);
  Result := Node <> nil;
end;

function TJSONNode.Force(const Path: AnsiString): TJSONNode;
var
  N: TJSONNode;
  A, B: PChar;
  S: AnsiString;
begin
  Result := nil;
  // AsObject;
  if Path = '' then
  begin
    N := Child('');
    if N = nil then
      N := Add('');
    Exit(N);
  end;
  if Path[1] = '/' then
  begin
    N := Self;
    while N.Parent <> nil do
      N := N.Parent;
  end
  else
    N := Self;
  A := PChar(Path);
  if A^ = '/' then
  begin
    Inc(A);
    if A^ = #0 then
      Exit(N);
  end;
  if A^ = #0 then
  begin
    N := Child('');
    if N = nil then
      N := Add('');
    Exit(N);
  end;
  B := A;
  while B^ > #0 do
  begin
    if B^ = '/' then
    begin
      SetString(S, A, B - A);
      if N.Child(S) = nil then
        N := N.Add(S)
      else
        N := N.Child(S);
      A := B + 1;
      B := A;
    end
    else
    begin
      Inc(B);
      if B^ = #0 then
      begin
        SetString(S, A, B - A);
        if N.Child(S) = nil then
          N := N.Add(S)
        else
          N := N.Child(S);
      end;
    end;
  end;
  Result := N;
end;

function TJSONNode.Format(const Indent: AnsiString): AnsiString;

  function EnumNodes: AnsiString;
  var
    I, J: Integer;
    S: AnsiString;
  begin
    if (FList = nil) or (FList.Count = 0) then
      Exit(' ');
    Result := #10;
    J := FList.Count - 1;
    S := Indent + #9;
    for I := 0 to J do
    begin
      Result := Result + TJSONNode(FList[I]).Format(S);
      if I < J then
        Result := Result + ','#10
      else
        Result := Result + #10 + Indent;
    end;
  end;

var
  Prefix: AnsiString;
begin
  Result := '';
  if (FParent <> nil) and (FParent.FKind = nkObject) then
    Prefix := JsonStringEncode(FName) + ': '
  else
    Prefix := '';
  case FKind of
    nkObject: Result := Indent + Prefix +'{' + EnumNodes + '}';
    nkArray: Result := Indent + Prefix + '[' + EnumNodes + ']';
  else
    Result := Indent + Prefix + FValue;
  end;
end;

function TJSONNode.FormatCompact: AnsiString;

  function EnumNodes: AnsiString;
  var
    I, J: Integer;
  begin
    Result := '';
    if (FList = nil) or (FList.Count = 0) then
      Exit;
    J := FList.Count - 1;
    for I := 0 to J do
    begin
      Result := Result + TJSONNode(FList[I]).FormatCompact;
      if I < J then
        Result := Result + ',';
    end;
  end;

var
  Prefix: AnsiString;
begin
  Result := '';
  if (FParent <> nil) and (FParent.FKind = nkObject) then
    Prefix := JsonStringEncode(FName) + ':'
  else
    Prefix := '';
  case FKind of
    nkObject: Result := Prefix + '{' + EnumNodes + '}';
    nkArray: Result := Prefix + '[' + EnumNodes + ']';
  else
    Result := Prefix + FValue;
  end;
end;

function TJSONNode.ToString: AnsiString;
begin
  Result := Format('');
end;

function TJSONNode.GetCount: Integer;
begin
  if FList <> nil then
    Result := FList.Count
  else
    Result := 0;
end;

{ Json helper routines }

function JsonValidate(const Json: AnsiString): Boolean;
var
  N: TJSONNode;
begin
  N := TJSONNode.Create;
  try
    Result := N.TryParse(Json);
  finally
    N.Free;
  end;
end;

function JsonNumberValidate(const N: AnsiString): Boolean;
var
  C: PChar;
  T: TJSONToken;
begin
  C := PChar(N);
  Result := NextToken(C, T) and (T.Kind = tkNumber) and (T.Value = N);
end;

function JsonStringValidate(const S: AnsiString): Boolean;
var
  C: PChar;
  T: TJSONToken;
begin
  C := PChar(S);
  Result := NextToken(C, T) and (T.Kind = tkString) and (T.Value = S);
end;

{ Convert a pascal string to a json string }

function JsonStringEncode(const S: AnsiString): AnsiString;

  function Len(C: PChar): Integer;
  var
    I: Integer;
  begin
    I := 0;
    while C^ > #0 do
    begin
      if C^ < ' ' then
        if C^ in [#8..#13] then
          Inc(I, 2)
        else
          Inc(I, 6)
      else if C^ in ['"', '\'] then
        Inc(I, 2)
      else
        Inc(I);
      Inc(C);
    end;
    Result := I + 2;
  end;

const
  EscapeChars: PChar = '01234567btnvfr';
  HexChars: PChar = '0123456789ABCDEF';
var
  C: PChar;
  R: AnsiString;
  I: Integer;
begin
  if S = '' then
    Exit('""');
  C := PChar(S);
  R := '';
  SetLength(R, Len(C));
  R[1] := '"';
  I := 2;
  while C^ > #0 do
  begin
    if C^ < ' ' then
    begin
      R[I] := '\';
      Inc(I);
      if C^ in [#8..#13] then
        R[I] := EscapeChars[Ord(C^)]
      else
      begin
        R[I] := 'u';
        R[I + 1] := '0';
        R[I + 2] := '0';
        R[I + 3] := HexChars[Ord(C^) div $10];
        R[I + 4] := HexChars[Ord(C^) mod $10];
        Inc(I, 4);
      end;
    end
    else if C^ in ['"', '\'] then
    begin
      R[I] := '\';
      Inc(I);
      R[I] := C^;
    end
    else
      R[I] := C^;
    Inc(I);
    Inc(C);
  end;
  R[Length(R)] := '"';
  Result := R;
end;

{ Convert a json string to a pascal string }

function UnicodeToString(C: LongWord): AnsiString;
begin
  if C = 0 then
    Result := #0
  else if C < $80 then
    Result := Chr(C)
  else if C < $800 then
    Result := Chr((C shr $6) + $C0) + Chr((C and $3F) + $80)
  else if C < $10000 then
    Result := Chr((C shr $C) + $E0) + Chr(((C shr $6) and
      $3F) + $80) + Chr((C and $3F) + $80)
  else if C < $200000 then
    Result := Chr((C shr $12) + $F0) + Chr(((C shr $C) and
      $3F) + $80) + Chr(((C shr $6) and $3F) + $80) +
      Chr((C and $3F) + $80)
  else
    Result := '';
end;

function UnicodeToSize(C: LongWord): Integer;
begin
  if C = 0 then
    Result := 1
  else if C < $80 then
    Result := 1
  else if C < $800 then
    Result := 2
  else if C < $10000 then
    Result := 3
  else if C < $200000 then
    Result := 4
  else
    Result := 0;
end;

function HexToByte(C: Char): Byte; inline;
const
  Zero = Ord('0');
  UpA = Ord('A');
  LoA = Ord('a');
begin
  if C < 'A' then
    Result := Ord(C) - Zero
  else if C < 'a' then
    Result := Ord(C) - UpA + 10
  else
    Result := Ord(C) - LoA + 10;
end;

function HexToInt(A, B, C, D: Char): Integer; inline;
begin
  Result := HexToByte(A) shl 12 or HexToByte(B) shl 8 or HexToByte(C) shl 4 or
    HexToByte(D);
end;

function JsonStringDecode(const S: AnsiString): AnsiString;

  function Len(C: PChar): Integer;
  var
    I, J: Integer;
  begin
    if C^ <> '"'  then
      Exit(0);
    Inc(C);
    I := 0;
    while C^ <> '"' do
    begin
      if C^ = #0 then
        Exit(0);
      if C^ = '\' then
      begin
        Inc(C);
        if C^ = 'u' then
        begin
          if (C[1] in Hex) and (C[2] in Hex) and (C[3] in Hex) and (C[4] in Hex) then
          begin
            J := UnicodeToSize(HexToInt(C[1], C[2], C[3], C[4]));
            if J = 0 then
              Exit(0);
            Inc(I, J - 1);
            Inc(C, 4);
          end
          else
            Exit(0);
        end
        else if C^ = #0 then
          Exit(0)
      end;
      Inc(C);
      Inc(I);
    end;
    Result := I;
  end;

const
  Escape = ['b', 't', 'n', 'v', 'f', 'r'];
var
  C: PAnsiChar;
  R: AnsiString;
  I, J: Integer;
  H: AnsiString;
begin
  C := PChar(S);
  I := Len(C);
  if I < 1 then
    Exit('');
  R := '';
  SetLength(R, I);
  I := 1;
  Inc(C);
  while C^ <> '"' do
  begin
    if C^ = '\' then
    begin
      Inc(C);
      if C^ in Escape then
      case C^ of
        'b': R[I] := #8;
        't': R[I] := #9;
        'n': R[I] := #10;
        'v': R[I] := #11;
        'f': R[I] := #12;
        'r': R[I] := #13;
      end
      else if C^ = 'u' then
      begin
        H := UnicodeToString(HexToInt(C[1], C[2], C[3], C[4]));
        for J := 1 to Length(H) - 1 do
        begin
          R[I] := H[J];
          Inc(I);
        end;
        R[I] := H[Length(H)];
        Inc(C, 4);
      end
      else
        R[I] := C^;
    end
    else
      R[I] := C^;
    Inc(C);
    Inc(I);
  end;
  Result := R;
end;

function JsonToXml(const S: AnsiString): AnsiString;
const
  Kinds: array[TJSONNodeKind] of AnsiString =
    (' kind="object"', ' kind="array"', ' kind="bool"', ' kind="null"', ' kind="number"', '');
  Space = '    ';

  function Escape(N: TJSONNode): AnsiString;
  begin
    Result := N.Value;
    if N.Kind = nkString then
    begin
      Result := JsonStringDecode(Result);
      Result := StringReplace(Result, '<', '&lt;', [rfReplaceAll]);
      Result := StringReplace(Result, '>', '&gt;', [rfReplaceAll]);
    end;
  end;

  function EnumNodes(P: TJSONNode; const Indent: AnsiString): AnsiString;
  var
    N: TJSONNode;
    S: AnsiString;
  begin
    Result := '';
    if P.Kind = nkArray then
      S := 'item'
    else
      S := '';
    for N in P do
    begin
      Result := Result + Indent + '<' + S + N.Name + Kinds[N.Kind];
      case N.Kind of
        nkObject, nkArray:
          if N.Count > 0 then
            Result := Result +  '>'#10 + EnumNodes(N, Indent + Space) +
              Indent + '</' + S + N.Name + '>'#10
          else
            Result := Result + '/>'#10;
        nkNull: Result := Result + '/>'#10;
      else
        Result := Result + '>' + Escape(N) + '</' +  S + N.Name + '>'#10;
      end;
    end;
  end;

var
  N: TJSONNode;
begin
  Result := '';
  N := TJSONNode.Create;
  try
    if N.TryParse(S) then
    begin
      Result :=
        '<?xml version="1.0" encoding="UTF-8"?>'#10 +
        '<root' +  Kinds[N.Kind];
        if N.Count > 0 then
          Result := Result +  '>'#10 + EnumNodes(N, Space) + '</root>'
        else
          Result := Result + '/>';
    end;
  finally
    N.Free;
  end;
end;

end.
