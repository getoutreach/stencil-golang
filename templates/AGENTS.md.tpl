{{- file.Skip "Virtual file for AGENTS.md module hooks from stencil-base" }}

{{- define "golangGenericCommands" }}

# golang
make gogenerate # Run go generate to create any generated code, such as protobufs or Kubernetes CRDs.
go mod tidy # Ensure your go.mod and go.sum files are up to date.
{{- end }}

{{ stencil.AddToModuleHook "github.com/getoutreach/stencil-base" "agentsGenericCommands" (list (stencil.ApplyTemplate "golangGenericCommands")) }}

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

{{ stencil.AddToModuleHook "github.com/getoutreach/stencil-base" "agentsDirectoryStructure" (list (stencil.ApplyTemplate "golangDirectoryStructure")) }}

{{- define "golangReferences" }}
| Idiomatic Go practices | [webpage](https://dmitri.shuralyov.com/idiomatic-go) |
| Effective Go | [webpage](https://go.dev/doc/effective_go) |
{{- end }}

{{ stencil.AddToModuleHook "github.com/getoutreach/stencil-base" "agentsReferencesTable" (list (stencil.ApplyTemplate "golangReferences")) }}

{{- define "golangBoundariesAlways" }}
- Run `go mod tidy` after adding, removing or upgrading Go dependencies
- Run `make gogenerate` after modifying protobuf definitions or interfaces with generated code
- Add context to errors using `fmt.Errorf("...: %w", err)`
- Prefer `gotest.tools/v3/assert` in tests over `github.com/stretchr/testify` or hand-rolled assertions
{{- end }}

{{ stencil.AddToModuleHook "github.com/getoutreach/stencil-base" "agentsBoundariesAlways" (list (stencil.ApplyTemplate "golangBoundariesAlways")) }}

{{- define "golangBoundariesAsk" }}
{{- end }}

{{ stencil.AddToModuleHook "github.com/getoutreach/stencil-base" "agentsBoundariesAsk" (list (stencil.ApplyTemplate "golangBoundariesAsk")) }}

{{- define "golangBoundariesNever" }}
- Use `panic()` in production code paths
{{- end }}

{{ stencil.AddToModuleHook "github.com/getoutreach/stencil-base" "agentsBoundariesNever" (list (stencil.ApplyTemplate "golangBoundariesNever")) }}
