{{- $_ := stencil.ApplyTemplate "skipGrpcClient" "node" -}}
{{- if stencil.Arg "service" }}
export * as {{ stencil.ApplyTemplate "serviceNameLanguageSafe" }}Types from './grpc/{{ .Config.Name }}_pb';
export * from './client-helpers';

// <<Stencil::Block(nodeIndexExports)>>
{{ file.Block "nodeIndexExports" }}
// <</Stencil::Block>>

import { {{ stencil.ApplyTemplate "serviceNameLanguageSafe" }}Client } from './grpc/{{ .Config.Name }}_grpc_pb';
export default {{ stencil.ApplyTemplate "serviceNameLanguageSafe" }}Client;
{{- end }}
