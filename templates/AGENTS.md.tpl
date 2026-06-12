{{- file.Skip "Virtual file for AGENTS.md module hooks from stencil-base" }}

{{- define "golangStenciledCommands" }}

# golang
make gogenerate # Run go generate to create any generated code, such as protobufs or Kubernetes CRDs.
go mod tidy # Ensure your go.mod and go.sum files are up to date.
{{- end }}

{{ stencil.AddToModuleHook "github.com/getoutreach/stencil-base" "stenciledCommands" (list (stencil.ApplyTemplate "golangStenciledCommands")) }}

{{- define "golangDirectoryStructure" }}
  {{- if (stencil.Arg "service") }}
* `api/`: API definitions, such as protobuf files and OpenAPI specifications
* `bin/`: generated project executables.
* `cmd/`: main CLI Go code
* `deployments/`: Container publishing configuration
* `internal/`: internal (non-public) Go packages
* `testdata/`: test fixtures and other test data
  {{- end }}
* `scripts/`: internal development shell scripts _(**deprecated**, prefer to use `mise` tasks when appropriate)_
* `.vscode/`: VSCode configuration files
{{- end }}

{{ stencil.AddToModuleHook "github.com/getoutreach/stencil-base" "directoryStructure" (list (stencil.ApplyTemplate "golangDirectoryStructure")) }}

{{- define "golangReferences" }}
{{- end }}

{{ stencil.AddToModuleHook "github.com/getoutreach/stencil-base" "referencesTable" (list (stencil.ApplyTemplate "golangReferences")) }}

{{- define "golangBoundariesAlways" }}
{{- end }}

{{ stencil.AddToModuleHook "github.com/getoutreach/stencil-base" "agentsBoundariesAlways" (list (stencil.ApplyTemplate "golangBoundariesAlways")) }}

{{- define "golangBoundariesAsk" }}
{{- end }}

{{ stencil.AddToModuleHook "github.com/getoutreach/stencil-base" "agentsBoundariesAsk" (list (stencil.ApplyTemplate "golangBoundariesAsk")) }}

{{- define "golangBoundariesNever" }}
{{- end }}

{{ stencil.AddToModuleHook "github.com/getoutreach/stencil-base" "agentsBoundariesNever" (list (stencil.ApplyTemplate "golangBoundariesNever")) }}
