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

{{- define "golangComponents" }}
What are components? (golang)
{{- end }}

{{ stencil.AddToModuleHook "github.com/getoutreach/stencil-base" "agentsComponents" (list (stencil.ApplyTemplate "golangComponents")) }}

{{- define "golangAgentsOther" }}
Other agent information (golang)
{{- end }}

{{ stencil.AddToModuleHook "github.com/getoutreach/stencil-base" "agentsOther" (list (stencil.ApplyTemplate "golangAgentsOther")) }}
