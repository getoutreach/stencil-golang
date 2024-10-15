{{- $_ := stencil.ApplyTemplate "skipGrpcClient" "node" -}}
{
  "compilerOptions": {
    "module": "commonjs",
    "declaration": true,
    "esModuleInterop": true,
    "target": "ES2022",
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
    {{- /* This 'typeroots' is required to be here to prevent tsc from including conflicting types
    from BOTH node_modules/ and ../../../node_modules/ (in the root of the generated service). This
    line prevents the default tsc behavior (a terrible default, ugh) by limiting typescript types to
    only those found in the api/clients/nodes/node_modules/@types/ folder and nowhere else.
    */ -}}
    "typeRoots": ["node_modules/@types"],
    "lib": ["es2022"]
  },
  "include": ["src/**/*.ts", "src/**/*.js"],
  "exclude": ["node_modules", "codegen-templates"]
}
