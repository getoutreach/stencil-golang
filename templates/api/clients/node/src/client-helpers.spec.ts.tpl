{{- $_ := stencil.ApplyTemplate "skipGrpcClient" "node" -}}
{{- if not (stencil.Arg "service") }}
{{- $_ := file.Skip "No client generated for libraries" }}
{{- end }}
describe('{{ .Config.Name }} client', () => {
  it('asserts true # please fill this test in with your own', () => {
    expect(true).toBeTruthy();
  });
});
