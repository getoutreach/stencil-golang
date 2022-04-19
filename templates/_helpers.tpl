{{- file.Skip "Exposes template functions" }}

# Returns the currentYear in UTC
{{- define "currentYear" }}
{{- dateInZone "2006" (now) "UTC" }}
{{- end }}

# Returns a underscored version of the application's name
# that's safe to be used in packages
{{- define "goPackageSafeName" }}
{{- regexReplaceAll "\W+" .Config.Name "_"  }}
{{- end }}

# Returns the copyright string
{{- define "copyright" }}
{{- printf "Copyright %s Outreach Corporation. All Rights Reserved." (stencil.ApplyTemplate "currentYear") }}
{{- end }}

# Returns the import path for this application
{{- define "appImportPath" }}
{{- printf "github.com/%s/%s" .Runtime.Box.Org .Config.Name }}
{{- end }}

{{- define "dependencies" }}
go:
- name: github.com/getoutreach/gobox
  version: v1.37.0
{{- if not (stencil.Arg "oss") }}
- name: github.com/getoutreach/mint
  version: v1.51.0
- name: github.com/getoutreach/httpx
  version: v1.12.1
- name: github.com/getoutreach/services
  version: v1.79.1
- name: github.com/getoutreach/datastores/v2
  version: v2.17.0
{{- end }}

{{- if .grpc }}
- name: github.com/getoutreach/tollmon
  version: v1.26.0
- name: google.golang.org/grpc
  version: v1.37.0
- name: github.com/getoutreach/orgservice
  version: v1.39.0
{{- end }}

{{- if stencil.Args "commands" }}
- name: github.com/urfave/cli/v2
  version: v2.3.0
{{- end }}

{{- range := stencil.GetModuleHook "go_modules" }}
- name: {{ .Name }}
  version: {{ .Version }}
{{- end }}

nodejs:
  dependencies:
  - name: "@grpc/grpc-js"
    version: ^1.3.5
  - name: "@grpc/proto-loader"
    version: ^0.5.5
  - name: "@outreach/grpc-client"
    version: ^2.1.0
  - name: "@outreach/find"
    version: ^1.0.1
  - name: "@types/google-protobuf"
    version: ^3.7.4
  - name: google-protobuf
    version: ^3.13.0
  - name: ts-enum-util
    version: ^4.0.2
  - name: winston
    version: ^3.3.3
{{- range := stencil.GetModuleHook "js_modules" }}
  - name: {{ .Name }}
    version: {{ .Version }}
{{- end }}
  devDependencies:
  - name: "@outreach/eslint-config"
    version: ^1.0.4
  - name: "@outreach/prettier-config"
    version: ^1.0.3
  - name: "@types/jest"
    version: ^26.0.15
  - name: "@typescript-eslint/eslint-plugin"
    version: ^2.33.0
  - name: "@typescript-eslint/parser"
    version: ^2.33.0
  - name: eslint
    version: ^7.13.0
  - name: eslint-config-prettier
    version: ^6.15.0
  - name: eslint-plugin-jest
    version: ^24.1.3
  - name: eslint-plugin-jsdoc
    version: ^30.7.7
  - name: eslint-plugin-lodash
    version: ^7.1.0
  - name: eslint-plugin-node
    version: ^11.1.0
  - name: grpc-tools
    version: ^1.9.1
  - name: grpc_tools_node_protoc_ts
    version: ^5.0.1
  - name: jest
    version: ^26.6.3
  - name: npm-run-all
    version: ^4.1.5
  - name: prettier
    version: ^2.1.2
  - name: rimraf
    version: ^3.0.2
  - name: ts-jest
    version: ^26.4.4
  - name: ts-node
    version: ^9.0.0
  - name: tsconfig-paths
    version: ^3.9.0
  - name: typescript
    version: ^4.0.5
  - name: wait-on
    version: ^5.2.0
{{- range := stencil.GetModuleHook "js_modules_dev" }}
  - name: {{ .Name }}
    version: {{ .Version }}
{{- end }}
{{- end }}
