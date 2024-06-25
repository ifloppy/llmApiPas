unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fphttpclient, Forms, Controls, Graphics, Dialogs, StdCtrls,
  ExtCtrls,
  ollamaPas;

type

  { TForm1 }

  TForm1 = class(TForm)
    Button1: TButton;
    Edit1: TEdit;
    Label1: TLabel;
    LabeledEdit1: TLabeledEdit;
    LabeledEdit2: TLabeledEdit;
    Memo1: TMemo;
    procedure Button1Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    llm: TOllama;
    procedure client(Token: string; EOF: boolean);
    procedure CallLLM();
  public

  end;

var
  Form1: TForm1;

implementation

{$R *.lfm}

{ TForm1 }

procedure TForm1.Button1Click(Sender: TObject);
begin
  Memo1.Clear;
  TThread.ExecuteInThread(@CallLLM);
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  llm:=TOllama.Create(Edit1.Text, LabeledEdit1.Text);
end;

procedure TForm1.FormDestroy(Sender: TObject);
begin
  llm.Free;
end;

procedure TForm1.client(Token: string; EOF: boolean);
begin
  Memo1.Text := Memo1.Text + Token;
  if EOF then begin
     Memo1.Append('(EOF)');
  end;
end;

procedure TForm1.CallLLM();
begin
  llm.Generate(LabeledEdit2.Text, @client);
end;

end.

