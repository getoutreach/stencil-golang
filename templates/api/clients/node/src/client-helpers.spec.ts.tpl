{{- $_ := stencil.ApplyTemplate "skipGrpcClient" "node" -}}
describe('{{ .Config.Name }} client', () => {
  it('asserts true # please fill this test in with your own', () => {
    expect(true).toBeTruthy();
  });
});
