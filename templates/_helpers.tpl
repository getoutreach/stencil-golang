{{- file.Skip "Exposes template functions" }}

{{- if and (not (stencil.Arg "service")) (not (empty (stencil.Arg "serviceActivities"))) }}
{{ fail "service has to be set to \"true\" in order to supply \"serviceActivities\"" }}
{{- end }}

# This will be better when we rollout the versions functionality
# in stencil later.
{{- define "goVersion" }}
{{- stencil.Arg "versions.go" -}}
{{- end }}

{{- define "toolVersions" }}
- name: golang
  version: {{ stencil.ApplyTemplate "goVersion" | trim | squote }}
# Not used for gRPC clients
- name: nodejs
  version: 16.13.0
- name: terraform
  version: 0.13.5
# Just in case bundler/etc needs to be used in the root.
- name: ruby
  version: 2.7.5
# Used in CI
- name: protoc
  version: 21.5
{{- end }}

# Registers our versions w/ stencil-base
{{ stencil.AddToModuleHook "github.com/getoutreach/stencil-base" "toolVersions" (stencil.ApplyTemplate "toolVersions" | fromYaml) }}

# Returns the currentYear in UTC
{{- define "currentYear" }}
{{- dateInZone "2006" (now) "UTC" }}
{{- end }}

# Returns a underscored version of the application's name
# that's safe to be used in packages
{{- define "goPackageSafeName" }}
{{- regexReplaceAll "\\W+" .Config.Name "_"  }}
{{- end }}

# Skips the current file if a node client shouldn't be generated
# {{- $_ := stencil.ApplyTemplate "skipGrpcClient" "node" -}}
{{- define "skipGrpcClient" }}
{{- $grpcClient := . }}
{{- $serviceActivities := (stencil.Arg "serviceActivities") }}
{{- $grpcClients := (stencil.Arg "grpcClients") }}
{{- if not (and (has "grpc" $serviceActivities) (has $grpcClient $grpcClients)) }}
  {{ file.Skip (printf "Not a gRPC service, or %s client not specified in grpcClients" $grpcClient) }}
  {{ file.Delete }}
{{- end }}
{{- end }}

{{- /* skipIfNotService skips the current file if we're not a service */}}
{{- define "skipIfNotService" }}
{{- if not (stencil.Arg "service") }}
  {{ file.Skip "Not a service" }}
  {{ file.Delete }}
{{- end }}
{{- end }}


# Returns the copyright string
{{- define "copyright" }}
{{- printf "Copyright %s Outreach Corporation. All Rights Reserved." (stencil.ApplyTemplate "currentYear") }}
{{- end }}

# Returns the import path for this application.
{{- define "appImportPath" }}
{{- list "github.com" .Runtime.Box.Org .Config.Name | join "/" }}
{{- end }}

# Service names may have hyphens in them, but Golang structs and Protobuf
# services may NOT have hyphens in their name. To keep generated code valid,
# convert the service name 'example-service' into 'ExampleService' for
# compatibility.
{{- define "serviceNameLanguageSafe" }}
{{- regexReplaceAllLiteral "\\W+" .Config.Name " " | title | replace " " "" }}
{{- end }}


# Add requested required dependencies that weren't already programmatically added by
# another stencil module (to the devenv.dependencies.required module hook).
{{- range (stencil.Arg "dependencies.required") }}
	{{- if not (has . (stencil.GetModuleHook "devenv.dependencies.required")) }}
		{{ stencil.AddToModuleHook "github.com/getoutreach/stencil-golang" "devenv.dependencies.required" (list .) }}
	{{- end }}
{{- end }}

# Add requested optional dependencies that weren't already programmatically added by
# another stencil module (to the devenv.dependencies.optional module hook).
{{- range (stencil.Arg "dependencies.optional") }}
	{{- if not (has . (stencil.GetModuleHook "devenv.dependencies.optional")) }}
		{{ stencil.AddToModuleHook "github.com/getoutreach/stencil-golang" "devenv.dependencies.optional" (list .) }}
	{{- end }}
{{- end }}

# Dependencies for the service
{{- define "dependencies" }}
go:
- name: github.com/getoutreach/gobox
  version: v1.54.0

{{- if has "grpc" (stencil.Arg "serviceActivities") }}
- name: google.golang.org/grpc
  version: v1.37.0
- name: github.com/getoutreach/orgservice
  version: v1.63.0
{{- end }}

{{- if stencil.Arg "commands" }}
- name: github.com/urfave/cli/v2
  version: v2.16.3
{{- end }}

{{- if stencil.Arg "kubernetes.groups" }}
- name: k8s.io/apimachinery
  version: v0.23.0
- name: k8s.io/client-go
  version: v0.23.0
- name: sigs.k8s.io/controller-runtime
  version: v0.9.6
{{- end }}

{{- range stencil.GetModuleHook "go_modules" }}
- name: {{ .name }}
  version: {{ .version }}
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
{{- range stencil.GetModuleHook "js_modules" }}
  - name: {{ .name }}
    version: {{ .version }}
{{- end }}
  devDependencies:
  - name: "@outreach/eslint-config"
    version: ^1.0.4
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
{{- range stencil.GetModuleHook "js_modules_dev" }}
  - name: {{ .name }}
    version: {{ .version }}
{{- end }}
{{- end }}
