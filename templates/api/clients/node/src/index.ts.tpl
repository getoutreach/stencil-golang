{{- $_ := stencil.ApplyTemplate "skipGrpcClient" "node" -}}
export * as {{ title .Config.Name }}Types from './grpc/{{ .Config.Name }}_pb';
export * from './client-helpers';

import { {{ title .Config.Name }}Client } from './grpc/{{ .Config.Name }}_grpc_pb';
export default {{ title .Config.Name }}Client;
