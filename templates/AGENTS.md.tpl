{{- file.Skip "Virtual file for AGENTS.md module hooks from stencil-base" }}

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
* Run `go mod tidy` to ensure your `go.mod` and `go.sum` files are up to date.
  {{- if (stencil.Arg "service") }}
* Use `make fmt` to format your code according to Go standards.
* Use `make lint` to run linters and catch potential issues in your code.
* Use `make test` to run your tests and ensure your code is working as expected.
  {{- end }}
{{- end }}

{{ stencil.AddToModuleHook "github.com/getoutreach/stencil-base" "agentsReferences" (list (stencil.ApplyTemplate "golangReferences")) }}

{{- define "golangAgentsOther" }}
{{- end }}

{{ stencil.AddToModuleHook "github.com/getoutreach/stencil-base" "agentsOther" (list (stencil.ApplyTemplate "golangAgentsOther")) }}
