unit MainUnit;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls;

type
  TForm1 = class(TForm)
    Button1: TButton;
    Memo1: TMemo;
    Memo2: TMemo;
    procedure FormCreate(Sender: TObject);
    procedure Memo2Change(Sender: TObject);
    procedure Button1Click(Sender: TObject);
  private

  public

  end;

var
  Form1: TForm1;

implementation

uses Parser.JSON, Parser.JSON;

{$R *.lfm}

{ TForm1 }

procedure TForm1.FormCreate(Sender: TObject);
begin
end;

procedure TForm1.Memo2Change(Sender: TObject);
begin

end;

procedure TForm1.Button1Click(Sender: TObject);
var
  j: TJsonNode;
begin
  j := TJsonNode.Create;
  try
    Memo2.Text := TYamlUtils.YamlToJson(Memo1.Text);
    j.Parse(Memo2.Text);
    Memo2.Text := j.AsJson;
  finally
    j.Free;
  end;
end;

end.

