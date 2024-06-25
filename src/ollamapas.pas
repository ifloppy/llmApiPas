unit ollamaPas;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, jsonparser, fpjson, fphttpclient,
  Dialogs;

const
  NewLine = #10;

type
  TOllamaGenerateCallback = procedure(Token: string; EOF: boolean) of object;

  TOllamaThreadParameter = record
    CallbackFunction: TOllamaGenerateCallback;
    ResponseStream: TStringStream;
  end;

  TOllama = class(TObject)
    constructor Create(endpoint: string; modelName: string);
    destructor Destroy; override;
    function Generate(prompt: string; callback: TOllamaGenerateCallback): boolean;
  protected
    BaseURL: string;
    Model: string;



    client: TFPHTTPClient;

    EOF: boolean;
  end;

implementation

procedure StreamReader(parameter: Pointer);
var
  buffer, buffer_char, response: string;
  json: TJSONObject;
  Done: boolean = False;
  Param: ^TOllamaThreadParameter;
  current_pos: integer = 1;
begin
  Param := parameter;
  while (not Done) do
  begin

    //Read the latest line to buffer
    buffer := '';
    while not Done do
    begin
      if (current_pos < Param^.ResponseStream.Position) then
      begin
        buffer_char := Param^.ResponseStream.DataString[current_pos];
        buffer := buffer + buffer_char;
        Inc(current_pos);
        if buffer_char = NewLine then break;
      end else begin
        Sleep(10);
      end;

    end;



    json := GetJSON(buffer) as TJSONObject;
    if json.Count > 0 then
    begin
      if json.Booleans['done'] = True then
      begin
        Done := True;
      end;
      response := json.Strings['response'];

      Param^.CallbackFunction(response, Done);
    end;
    json.Free;

  end;
end;

constructor TOllama.Create(endpoint: string; modelName: string);
begin
  inherited Create;
  client := TFPHTTPClient.Create(nil);
  BaseURL := endpoint;
  Model := modelName;
end;

destructor TOllama.Destroy;
begin
  client.Free;
end;

function TOllama.Generate(prompt: string; callback: TOllamaGenerateCallback): boolean;
var
  RequestData: TJSONObject;
  ResponseData: TStringStream;
  ThreadParameter: TOllamaThreadParameter;
  StreamReaderThread: TThread;
begin
  RequestData := TJSONObject.Create;
  RequestData.Add('model', Model);
  RequestData.Add('prompt', prompt);
  ResponseData := TStringStream.Create;

  ThreadParameter.CallbackFunction := callback;
  ThreadParameter.ResponseStream := ResponseData;

  StreamReaderThread := TThread.ExecuteInThread(@StreamReader, @ThreadParameter);

  Result := True;
  try
    client.FormPost(BaseURL + '/api/generate', RequestData.AsJSON, ResponseData);
  except
    Result := False;
  end;
  ResponseData.WriteString(#10);//For recognizing end of line

  ResponseData.SaveToFile('output.log');

  RequestData.Free;

  StreamReaderThread.WaitFor;

  ResponseData.Free;

end;



end.
