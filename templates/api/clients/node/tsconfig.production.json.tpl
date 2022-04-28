{{- $_ := stencil.ApplyTemplate "skipGrpcClient" "node" -}}
{
  "extends": "./tsconfig.json",
  "exclude": ["node_modules", "codegen-templates", "**/*.spec.ts", "**/spec.ts"]
}
