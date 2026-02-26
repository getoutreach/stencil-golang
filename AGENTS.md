# AI Agent instructions

Ignore all lines containing "Stencil::Block".
These are template instructions and should not be included in the final output.

## Project overview

<!-- <<Stencil::Block(customProjectOverview)>> -->

<!-- <</Stencil::Block>> -->

## Project organization
* `api/`: API definitions, such as protobuf files and OpenAPI specifications
* `bin/`: generated project executables.
* `cmd/`: main CLI Go code
* `deployments/`: Container publishing configuration
* `internal/`: internal (non-public) Go packages
* `scripts/`: internal development shell scripts _(**deprecated**, prefer to use `mise` tasks when appropriate)_
* `testdata/`: test fixtures and other test data
* `.vscode/`: VSCode configuration files

If some of the directories do not exist, ignore their definitions.
If no directories are defined, find more information in `docs/` directory.

## Build and test commands
* Build command: `make build`
* Go code generation command: `make gogenerate`
* Linter command: `make lint`
* Formatter command: `make fmt`
* Unit test command (depends on linter command): `make test`

## Code style
Code linting is validated by the linter command above.

Go linters are run via `golangci-lint`. Its configuration is defined in `scripts/golangci.yml`.

Code formatting is enforced by running the formatter command above.

## Version control

### Commit message format

Commit messages must conform to the [Conventional Commits v1.0
specification](https://www.conventionalcommits.org/en/v1.0.0/). Acceptable types:

* `feat` (minor version bump) - user-facing feature that is not a breaking change.
* `fix` (patch version bump) - fix to an existing feature in the service or to the deployment
  configuration (jsonnet).
* `revert` (patch version bump) - reverts a previous commit, must include the ID of the commit
  in question.
* `perf` (patch version bump, does not change existing functionality)
* `refactor` (no version bump) - changes to the existing code that does not change existing
  functionality or performance.
* `ci` (no version bump) - related to the CI/CD system of the service.
* `build` (no version bump) - related to the build system that does not require
  a release.
* `docs` (no version bump) - related to the non-user-facing documentation.

DO NOT put Jira ticket IDs in the commit title. It SHOULD go into the commit description.

If a single prompt to a tool (e.g. GitHub Copilot) was used to create the commit, then the prompt
MUST be included in the commit description:
```
AI prompt: [Prompt]
```

Example:

```
AI prompt: rename all instances of "helper" to "agent", preserving existing formatting.
```

If a design spec was provided along with a prompt as input to a tool that produced a working change,
or a plan was generated through AI conversational prompts, the spec or detailed plan (without an
"implementation steps" section, or any instructions already covered in `AGENTS.md`) MUST be checked
in alongside the code in `documentation/specs/$jiraID/` (where `$jiraID` is the Jira ticket ID
associated with the design spec) and the prompt MUST be included in the commit description.

AI agents MUST disclose what tool and model they are using in the `Assisted-By` commit footer:

```
Assisted-By: [Model Name] via [Tool Name]
```

For example:
```
Assisted-By: LLM 1.2.3 via Claude Code
```

<!-- <<Stencil::Block(additionalAgentsInfo)>> -->

<!-- ## <</Stencil::Block>> -->
