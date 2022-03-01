program TesteInfo;

uses
  Vcl.Forms,
  uPrincipal in 'uPrincipal.pas' {fmCadastro},
  uClienteModel in 'uClienteModel.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TfmCadastro, fmCadastro);
  Application.Run;
end.
