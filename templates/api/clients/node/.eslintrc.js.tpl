{{- $_ := stencil.ApplyTemplate "skipGrpcClient" "node" }}
module.exports = {
  extends: ['@getoutreach/eslint-config/node'],
};
