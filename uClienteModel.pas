unit uClienteModel;

interface

uses System.SysUtils, System.JSON, REST.Types, REST.Client,
  IdBaseComponent, IdComponent, IdTCPConnection, IdTCPClient,
  IdExplicitTLSClientServerBase, IdMessageClient, IdSMTPBase, IdSMTP,
  IdIOHandler, IdIOHandlerSocket, IdIOHandlerStack, IdSSL, IdSSLOpenSSL,
  IdMessage, Dialogs, XMLDoc, XMLIntf, Vcl.Forms, IdAttachmentFile;

type
  TEndereco = class
  private
    FCEP: string;
    FLogradouro: string;
    FNumero: integer;
    FComplemento: string;
    FBairro: string;
    FCidade: string;
    FEstado: string;
    FPais: string;
    procedure SetCEP(const AValue: string);
    function GetCEP: string;
    procedure SetNumero(const AValue: integer);
    function GetNumero: integer;
    function BuscaCEP(sCEP: string):boolean;
    { private declarations }
  protected
    { protected declarations }
  public

    { public declarations }
    property CEP: string read GetCEP write SetCEP;
    property Logradouro: string read FLogradouro write FLogradouro;
    property Numero: integer read GetNumero write SetNumero;
    property Complemento: string read FComplemento write FComplemento;
    property Bairro: string read FBairro write FBairro;
    property Cidade: string read FCidade write FCidade;
    property Estado: string read FEstado write FEstado;
    property Pais: string read FPais write FPais;

  published
    { published declarations }
  end;

  TCliente = class
  private
    FNome: string;
    FIdentidade: string;
    FCPF: string;
    FTelefone: string;
    FEmail: string;
    FEndereco: TEndereco;

    procedure SetNome(const AValue: string);
    function GetNome: string;
    procedure SetEmail(const AValue: string);
    function GetEmail: string;
    function GerarXml(oCliente: TCliente): string;
    { private declarations }
  protected
    { protected declarations }
  public
    Constructor Create;
    Destructor Destroy; Override;
    function EnviarEmail(pEmail: string; oCliente: TCliente): boolean;
    { public declarations }
    property Nome: string read GetNome write SetNome;
    property Identidade: string read FIdentidade write FIdentidade;
    property CPF: string read FCPF write FCPF;
    property Telefone: string read FTelefone write FTelefone;
    property Email: string read GetEmail write SetEmail;
    property Endereco: TEndereco read FEndereco write FEndereco;


  published
    { published declarations }
  end;

implementation

{ TCliente }

function TEndereco.BuscaCEP(sCEP: string): boolean;
var
  json: TJSONObject;
  RestClient: TRESTClient;
  RestRequest: TRESTRequest;
  RestResponse: TRESTResponse;
begin
  RestClient   := TRESTClient.Create(nil);
  RestRequest  := TRESTRequest.Create(nil);
  RestResponse := TRESTResponse.Create(nil);
  RestRequest.Client := RestClient;
  RestRequest.Response := RestResponse;

  try
    if sCEP <> EmptyStr then
    begin
      RestClient.BaseURL := 'https://viacep.com.br/ws/'+sCEP+'/json';
      RestRequest.Execute;
      if RestResponse.StatusCode <> 200 then
      begin
        raise Exception.Create('Cep Inválido!');
      end;

      json := RestResponse.JSONValue as TJSONObject;
      try
        if Assigned(json) then
        begin
          Logradouro := json.values['logradouro'].value;
          Complemento := json.values['complemento'].value;
          Bairro := json.values['bairro'].value;
          Cidade := json.values['localidade'].value;
          Estado := json.values['uf'].value;
          Pais := 'Brasil';
        end;
      finally
        FreeAndNil(RestClient);
        FreeAndNil(RestRequest);
        FreeAndNil(RestResponse);
      end;
    end;
  except
    on E: Exception do
    begin
      ShowMessage('Erro: ' + E.Message );
    end;
  end;
end;

function TEndereco.GetCEP: string;
begin
  Result := FCEP;
end;

function TEndereco.GetNumero: integer;
begin
  Result := FNumero;
end;

function TCliente.GetNome: string;
begin
  Result := FNome;
end;

procedure TEndereco.SetCEP(const AValue: string);
begin
  BuscaCEP(AValue);

  FCEP := AValue;
end;

procedure TEndereco.SetNumero(const AValue: integer);
begin
  if AValue.ToString = EmptyStr then
    FNumero := 0
  else
    FNumero := AValue;
end;

procedure TCliente.SetNome(const AValue: string);
begin
  if AValue = EmptyStr then
    raise Exception.Create('Nome não informado!');
  FNome := AValue;
end;

constructor TCliente.Create;
begin
  inherited Create;
  FEndereco := TEndereco.Create;
end;

destructor TCliente.Destroy;
begin

  inherited;
  FreeAndNil(FEndereco);
end;

function TCliente.EnviarEmail(pEmail: string; oCliente: TCliente): boolean;
var
  oSmtp: TIdSMTP;
  oMessage: TIdMessage;
  oHandle: TIdSSLIOHandlerSocketOpenSSL;
  arquivo: string;
begin
  result := false;
  if pEmail <> EmptyStr then
  begin
    oSmtp := TIdSMTP.Create();
    oMessage := TIdMessage.Create();
    oHandle := TIdSSLIOHandlerSocketOpenSSL.Create();
    arquivo := GerarXml(oCliente);
    with oSmtp do
    begin
      AuthType  := satDefault;
      Host := 'smtp.gmail.com';
      IOHandler := oHandle;
      Password := '*******';
      Port := 465;
      Username := 'vinialbertini86@gmail.com';
      UseTLS := utUseImplicitTLS;

    end;
    oHandle.SSLOptions.Method := sslvSSLv23;
    oHandle.SSLOptions.Mode := sslmClient;
    try
      with oMessage do
      begin
        oMessage.MessageParts.Clear;
        oMessage.From.Address := oSmtp.Username;
        oMessage.Subject := 'Xml Cadastro de Cliente';
        Body.Add('Segue em anexo os dados do cliente em xml.');
        Body.Add('');
        Body.Add('');
        Body.Add('Att.');
        TIdAttachmentFile.Create(MessageParts, TFileName(arquivo));
        oMessage.Recipients.EMailAddresses := trim(pEmail);
      end;

      if not oSmtp.Connected then
        oSmtp.Connect();
      if not oSmtp.Connected then
        raise Exception.Create('Erro na conexão com servidor de email!');
      try
        oSmtp.Send(oMessage);
        Application.ProcessMessages;
        Result := true;
      except
        on E: Exception do
        begin
          ShowMessage('Erro: ' + E.Message );
        end;
      end;
      ShowMessage('Email enviado com sucesso!');
    finally
      DeleteFile(arquivo);
      oSmtp.Disconnect;
      FreeAndNil(oSmtp);
      FreeAndNil(oMessage);
      FreeAndNil(oHandle);
    end;
  end
end;

function TCliente.GerarXml(oCliente: TCliente): string;
var
  XMLDocument: TXMLDocument;
  NodeCadastro, NodeCliente, NodeEndereco: IXMLNode;
  I: Integer;
begin
  XMLDocument := TXMLDocument.Create(nil);
  try
    XMLDocument.Active := True;
    NodeCadastro := XMLDocument.AddChild('Cadastro');
    NodeCliente := NodeCadastro.AddChild('Cliente');
    NodeCliente.ChildValues['Nome'] := oCliente.Nome;
    NodeCliente.ChildValues['Identidade'] := oCliente.Identidade;
    NodeCliente.ChildValues['CPF'] := oCliente.CPF;
    NodeCliente.ChildValues['Telefone'] := oCliente.Telefone;
    NodeCliente.ChildValues['Email'] := oCliente.Email;
    NodeEndereco := NodeCliente.AddChild('Endereco');
    NodeEndereco.ChildValues['Logradouro'] := oCliente.Endereco.Logradouro;
    NodeEndereco.ChildValues['Numero'] := oCliente.Endereco.Numero;
    NodeEndereco.ChildValues['Complemento'] := oCliente.Endereco.Complemento;
    NodeEndereco.ChildValues['Bairro'] := oCliente.Endereco.Bairro;
    NodeEndereco.ChildValues['Cidade'] := oCliente.Endereco.Cidade;
    NodeEndereco.ChildValues['Estado'] := oCliente.Endereco.Estado;
    NodeEndereco.ChildValues['Pais'] := oCliente.Endereco.Pais;
    XMLDocument.SaveToFile(ExtractFilePath(Application.ExeName)+'Teste.xml');
    Result := ExtractFilePath(Application.ExeName)+'Teste.xml';

  finally
    XMLDocument.Free;
  end;

end;

function TCliente.GetEmail: string;
begin
  Result := FEmail;
end;

procedure TCliente.SetEmail(const AValue: string);
begin
  if AValue = EmptyStr then
    raise Exception.Create('Email não informado!');
  FEmail := AValue;
end;


end.


