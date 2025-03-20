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
  version: {{ stencil.Arg "versions.nodejs" }}
# Used in CI
- name: protoc
  version: 21.5
{{- if has "ruby" (stencil.Arg "grpcClients") }}
- name: ruby
  version: {{ stencil.Arg "versions.grpcClients.ruby" }}
{{- end }}
{{- end }}

# Determines the CGO_ENABLED value
{{- define "cgoEnabled" -}}
{{- if stencil.Arg "enableCgo" -}}
1
{{- else -}}
0
{{- end -}}
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

# Return a title cased name from repo name
# that's safe to be used in GRPC codes
{{- define "goTitleCaseName" }}
{{- .Config.Name | replace "_" "-" | title | replace "-" "" -}}
{{- end }}

# Skips the current file if a Node.js gRPC client shouldn't be generated
# {{- $_ := stencil.ApplyTemplate "skipGrpcClient" "node" -}}
{{- define "skipGrpcClient" }}
{{- $grpcClient := . }}
{{- $serviceActivities := (stencil.Arg "serviceActivities") }}
{{- $grpcClients := (stencil.Arg "grpcClients") }}
{{- if not (and (or (not (stencil.Arg "service")) (has "grpc" $serviceActivities)) (has $grpcClient $grpcClients)) }}
  {{ $_ := file.Skip (printf "Not a gRPC service/library, or %s client not specified in grpcClients" $grpcClient) }}
{{- end }}
{{- end }}

{{- /* skipIfNotService skips the current file if we're not a service */}}
{{- define "skipIfNotService" }}
{{- if not (stencil.Arg "service") }}
  {{ file.Skip "Not a service" }}
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

{{- define "vaultSecrets" }}
secrets:
{{- range $secret := stencil.Arg "vaultSecrets"}}
- "{{ $secret }}"
{{- end }}
{{- range $secret := stencil.GetModuleHook "injectedVaultSecrets" }}
- "{{ $secret }}"
{{- end }}
{{- end }}

# Dependencies for the service
{{- define "dependencies" }}
go:
- name: github.com/getoutreach/gobox
  version: v1.104.0
- name: github.com/getoutreach/stencil-golang/pkg
  # To obtain, set `github.com/getoutreach/stencil-golang/pkg` to 'main'
  # in a go.mod and run `go mod tidy`.
  version: v0.0.0-20250109193043-fa44ea640e7e

{{- if has "grpc" (stencil.Arg "serviceActivities") }}
- name: google.golang.org/grpc
  version: v1.37.0
- name: github.com/getoutreach/orgservice
  version: v1.148.6
  # Used for grpcx
- name: github.com/getoutreach/services
  version: v1.218.0
{{- end }}
{{- if has "http" (stencil.Arg "serviceActivities") }}
- name: github.com/getoutreach/httpx
  version: v1.17.7
{{- end }}

{{- if stencil.Arg "commands" }}
- name: github.com/urfave/cli/v2
  version: v2.16.3
{{- end }}

{{- if stencil.Arg "kubernetes.groups" }}
- name: github.com/getoutreach/k8slib
  version: v1.0.0
- name: k8s.io/apimachinery
  version: v0.31.3
- name: k8s.io/client-go
  version: v0.31.0
- name: sigs.k8s.io/controller-runtime
  version: v0.19.0
{{- end }}

{{- range stencil.GetModuleHook "go_modules" }}
- name: {{ .name }}
  version: {{ .version }}
{{- end }}

nodejs:
  dependencies:
  - name: "@grpc/grpc-js"
    # This version should be synced with the same dependency in @getoutreach/grpc-client
    version: "1.8.22"
  - name: "@getoutreach/grpc-client"
    version: ^2.4.0
  - name: "@getoutreach/find"
    version: ^1.1.0
  - name: "@types/google-protobuf"
    version: ^3.15.0
  - name: google-protobuf
    version: ^3.15.0
  - name: ts-enum-util
    version: ^4.0.2
  - name: winston
    version: ^3.13.0
{{- range stencil.GetModuleHook "js_modules" }}
  - name: {{ .name }}
    version: {{ .version }}
{{- end }}
  devDependencies:
  - name: "@getoutreach/eslint-config"
    version: ^2.0.0
  - name: "@types/jest"
    version: ^26.0.15
  - name: "@typescript-eslint/eslint-plugin"
    version: ^7.8.0
  - name: "@typescript-eslint/parser"
    version: ^7.8.0
  - name: eslint
    version: ^8.57.0
  - name: eslint-plugin-jest
    version: ^28.3.0
  - name: eslint-plugin-jsdoc
    version: ^48.2.3
  - name: eslint-plugin-node
    version: ^11.1.0
  - name: grpc-tools
    version: ^1.12.4
  - name: grpc_tools_node_protoc_ts
    version: ^5.0.1
  - name: jest
    version: ^26.6.3
  - name: npm-run-all
    version: ^4.1.5
  - name: prettier
    version: ^3.0.0
  - name: ts-jest
    version: ^26.4.4
  - name: ts-node
    version: ^9.0.0
  - name: tsconfig-paths
    version: ^3.9.0
  - name: typescript
    version: ^4.9.5
{{- range stencil.GetModuleHook "js_modules_dev" }}
  - name: {{ .name }}
    version: {{ .version }}
{{- end }}
{{- end }}
