{{- $_ := stencil.ApplyTemplate "skipGrpcClient" "node" -}}
const { build } = require('@getoutreach/grpc-client');
const path = require('path');

build.copyDefinitions(path.resolve(__dirname, '..'));
