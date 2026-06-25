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
| Internal Go idioms | [webpage](https://outreach-io.atlassian.net/wiki/spaces/EN/pages/1124335785/Go+idioms) |
| Idiomatic Go practices | [webpage](https://dmitri.shuralyov.com/idiomatic-go) |
{{- end }}

{{ stencil.AddToModuleHook "github.com/getoutreach/stencil-base" "agentsReferencesTable" (list (stencil.ApplyTemplate "golangReferences")) }}

{{- define "golangBoundariesAlways" }}
- Run `go mod tidy` after adding or removing Go dependencies
- Run `make gogenerate` after modifying protobuf definitions or interfaces with generated code
- Follow idiomatic Go error handling (return errors, don't panic)
- Use structured logging (e.g., log.WithError(err).Error(...)) instead of fmt.Printf
- Add context to errors using `fmt.Errorf("...: %w", err)`
{{- end }}

{{ stencil.AddToModuleHook "github.com/getoutreach/stencil-base" "agentsBoundariesAlways" (list (stencil.ApplyTemplate "golangBoundariesAlways")) }}

{{- define "golangBoundariesAsk" }}
{{- end }}

{{ stencil.AddToModuleHook "github.com/getoutreach/stencil-base" "agentsBoundariesAsk" (list (stencil.ApplyTemplate "golangBoundariesAsk")) }}

{{- define "golangBoundariesNever" }}
- Use `panic()` in production code paths
{{- end }}

{{ stencil.AddToModuleHook "github.com/getoutreach/stencil-base" "agentsBoundariesNever" (list (stencil.ApplyTemplate "golangBoundariesNever")) }}
