# AI Agent instructions

Ignore lines containing "Stencil::Block"; they are areas in your generated code that you’d like to persist across runs and are repository specific. These lines are for template generator and do not contain agent instructions.

## Project purpose

<!-- <<Stencil::Block(projectPurpose)>> -->
Stencil Module for Golang Applications
<!-- <</Stencil::Block>> -->

## Directory structure
* `templates/`: Templates for generating project files, such as `AGENTS.md.tpl` for the AGENTS.md file. Used in stencil-modules to define the structure and content of generated files.
* `scripts/`: internal development shell scripts _(**deprecated**, prefer to use `mise` tasks when appropriate)_
* `.vscode/`: VSCode configuration files

* **./service.yaml**: File used as configuration for `stencil` program containing additional arguments and stencil modules to use
* **./stencil.lock**: File used as record for:
  1. What modules were used and their version
  2. What module owns which file
  3. If a file is not listed here, the owner is current repository

If you need more context, you can find more information in `docs/` directory. If the directory does not exist, ignore this line.

## References
* Run `go mod tidy` to ensure your `go.mod` and `go.sum` files are up to date.
* Run `make fmt` to format project.
* Run `make lint` to run linters on project's code.

<!-- <<Stencil::Block(agentsReferencesCustom)>> -->

<!-- <</Stencil::Block>> -->

## Other

<!-- <<Stencil::Block(agentsOtherCustom)>> -->

<!-- <</Stencil::Block>> -->
