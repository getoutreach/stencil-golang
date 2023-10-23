{{- $_ := stencil.ApplyTemplate "skipGrpcClient" "node" -}}
{
  "compilerOptions": {
    "module": "commonjs",
    "declaration": true,
    "esModuleInterop": true,
    "target": "es2018",
    "noImplicitAny": true,
    "moduleResolution": "node",
    "sourceMap": true,
    "strict": true,
    "outDir": "dist",
    "baseUrl": ".",
    "rootDir": "src",
    "experimentalDecorators": true,
    "emitDecoratorMetadata": true,
    "allowJs": true,
    "paths": {
      "@getoutreach/{{ .Config.Name }}-client": ["src"]
    },
    "lib": ["es2018", "es2018.promise", "esnext.asynciterable", "dom"]
  },
  "include": ["src/**/*.ts", "src/**/*.js"],
  "exclude": ["node_modules", "codegen-templates"]
}
