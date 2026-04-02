{{- $_ := stencil.ApplyTemplate "skipGrpcClient" "node" -}}
{
  "$schema": "./node_modules/oxlint/configuration_schema.json",
  "extends": ["./node_modules/@getoutreach/oxlint-config/node.json"],
  "ignorePatterns": [
    "typings/**/*",
    "src/grpc/**/*",
    "dist/**/*",
    "coverage/**/*"
  ]
}
