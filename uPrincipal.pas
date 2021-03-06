unit uPrincipal;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls, System.ImageList,
  Vcl.ImgList, Vcl.Buttons, Vcl.StdCtrls,  StrUtils, Math;

type
  TfmCadastro = class(TForm)
    Label2: TLabel;
    edNome: TEdit;
    Label4: TLabel;
    edEndereco: TEdit;
    Label3: TLabel;
    Label5: TLabel;
    edComplemento: TEdit;
    Label6: TLabel;
    edBairro: TEdit;
    Label7: TLabel;
    edCidade: TEdit;
    edUF: TEdit;
    edPais: TEdit;
    Label8: TLabel;
    Panel8: TPanel;
    sbSalvar: TSpeedButton;
    ImageList1: TImageList;
    edCEP: TButtonedEdit;
    Panel9: TPanel;
    sbCancelar: TSpeedButton;
    edNumero: TEdit;
    Label1: TLabel;
    edCPF: TEdit;
    Label9: TLabel;
    edTelefone: TEdit;
    Label10: TLabel;
    Label11: TLabel;
    edEmail: TEdit;
    Label12: TLabel;
    edIdentidade: TEdit;
    procedure edCEPRightButtonClick(Sender: TObject);
    procedure sbSalvarClick(Sender: TObject);
    procedure LimparCampos;
    procedure sbCancelarClick(Sender: TObject);
    procedure edNumeroKeyPress(Sender: TObject; var Key: Char);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  fmCadastro: TfmCadastro;

implementation

{$R *.dfm}

uses uClienteModel;

procedure TfmCadastro.edCEPRightButtonClick(Sender: TObject);
var oCliente: TCliente;
begin
  oCliente := TCliente.Create();
  try
    oCliente.Endereco.CEP := edCEP.Text;
    edEndereco.Text := oCliente.Endereco.Logradouro;
    edComplemento.Text := oCliente.Endereco.Complemento;
    edBairro.Text := oCliente.Endereco.Bairro;
    edCidade.Text := oCliente.Endereco.Cidade;
    edUF.Text := oCliente.Endereco.Estado;
    edPais.Text := oCliente.Endereco.Pais;
  finally
    edNumero.SetFocus;
    FreeAndNil(oCliente);
  end;
end;

procedure TfmCadastro.edNumeroKeyPress(Sender: TObject; var Key: Char);
begin
  if not (key in ['0'..'9',#8, #13]) then
    key := #0;
end;

procedure TfmCadastro.LimparCampos;
var
  i : Integer;
begin
  edCEP.Clear;
  for i := 0 to ComponentCount -1 do
  if Components[i] is TEdit then
  begin
    TEdit(Components[i]).Clear;
  end;
  edNome.SetFocus;
end;

procedure TfmCadastro.sbCancelarClick(Sender: TObject);
begin
  LimparCampos;
end;

procedure TfmCadastro.sbSalvarClick(Sender: TObject);
var oCliente: TCliente;
begin
  oCliente := TCliente.Create();
  try
    oCliente.Nome := edNome.Text;
    oCliente.Identidade := edIdentidade.Text;
    oCliente.Email := edEmail.Text;
    oCliente.CPF := edCPF.Text;
    oCliente.Telefone := edTelefone.Text;
    if edNumero.Text = EmptyStr then
      oCliente.Endereco.Numero := 0
    else
      oCliente.Endereco.Numero := StrToInt(edNumero.Text);
    oCliente.Endereco.CEP := edCEP.Text;
    oCliente.Endereco.Logradouro := edEndereco.Text;
    oCliente.Endereco.Complemento := edComplemento.Text;
    oCliente.Endereco.Bairro := edBairro.Text;
    oCliente.Endereco.Cidade := edCidade.Text;
    oCliente.Endereco.Estado := edUF.Text;
    oCliente.Endereco.Pais := edPais.Text;
    Screen.Cursor:= crHourGlass;
    if not oCliente.EnviarEmail(oCliente.Email, oCliente) then
      raise Exception.Create('Falha no envio de email!');
  finally
    LimparCampos;
    FreeAndNil(oCliente);
    Screen.Cursor:= crDefault;
  end;
end;

end.
