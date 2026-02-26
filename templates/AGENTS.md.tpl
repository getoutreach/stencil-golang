{{- file.Skip "Virtual file for AGENTS.md module hooks" }}

{{- define "golangProjectDirectories" }}
* `bin/`: generated project executables, if present.
* `cmd/`: main CLI Go code
* `deployments/`: Container publishing configuration
* `internal/`: internal (non-public) Go packages
* `orb/`: CircleCI orb definition
* `scripts/`: internal development shell scripts _(**deprecated**, prefer to use `mise` tasks when appropriate)_
* `testdata/`: test fixtures and other test data
{{- end }}

{{ stencil.AddToModuleHook "github.com/getoutreach/stencil-base" "projectDirectories" (list (stencil.ApplyTemplate "golangProjectDirectories")) }}

{{- define "golangProjectCommands" }}
* Build command: `make build`
* Go code generation command: `make gogenerate`
* Linter command: `make lint`
* Formatter command: `make fmt`
* Unit test command (depends on linter command): `make test`
{{- end }}

{{ stencil.AddToModuleHook "github.com/getoutreach/stencil-base" "projectCommands" (list (stencil.ApplyTemplate "golangProjectCommands")) }}

{{- define "golangProjectCodeStyle" }}
Code linting is validated by the linter command above.

Go linters are run via `golangci-lint`. Its configuration is defined in `scripts/golangci.yml`.

Code formatting is enforced by running the formatter command above.
{{- end }}

{{ stencil.AddToModuleHook "github.com/getoutreach/stencil-base" "projectCodeStyle" (list (stencil.ApplyTemplate "golangProjectCodeStyle")) }}
