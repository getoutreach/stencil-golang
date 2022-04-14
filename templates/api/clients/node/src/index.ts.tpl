export * as {{ .titleName }}Types from './grpc/{{ .appName }}_pb';
export * from './client-helpers';

import { {{ .titleName }}Client } from './grpc/{{ .appName }}_grpc_pb';
export default {{ .titleName }}Client;
