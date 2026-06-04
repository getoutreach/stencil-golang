# stencil-golang

Ignore lines containing "Stencil::Block"; they are areas in your generated code that you’d like to persist across runs and are repository specific. These lines are for template generator and do not contain agent instructions.

## Description

<!-- <<Stencil::Block(projectDescription)>> -->
Stencil module that scaffolds and maintains Golang applications and services.
<!-- <</Stencil::Block>> -->

## Project overview

<!-- <<Stencil::Block(projectOverview)>> -->
This repository is a Stencil module that scaffolds and maintains Golang
applications and services at Outreach. It provides `templates/` (`*.tpl`)
rendered by the `stencil` program—covering Go source, gRPC/HTTP APIs,
Kubernetes deployments, Dockerfiles, CI, and tooling config. Behavior is
driven by `service.yaml` arguments, while `Stencil::Block` regions preserve
repo-specific edits and `stencil.lock` tracks module versions and file ownership.
<!-- <</Stencil::Block>> -->

## Generic commands

```bash
# stencil
stencil # Run stencil program with arguments specified in service.yaml file
make fmt # Run formatters on project's code.
make lint # Run linters on project's code.

# golang
make gogenerate # Run go generate to create any generated code, such as protobufs or Kubernetes CRDs.
go mod tidy # Ensure your go.mod and go.sum files are up to date.

# <<Stencil::Block(customCommands)>>

# <</Stencil::Block>>
```

## Directory structure

* service.yaml: File used as configuration for `stencil` program containing additional arguments and stencil modules to use
* stencil.lock: File used as record for:
  1. What modules were used and their version
  2. What module owns which file
  3. If a file is not listed here, the owner is current repository
* docs/: Directory used to store documentation files and reference materials for the project.
* `templates/`: Templates for generating project files, such as `AGENTS.md.tpl` for the AGENTS.md file. Used in stencil-modules to define the structure and content of generated files.
* `scripts/`: internal development shell scripts _(**deprecated**, prefer to use `mise` tasks when appropriate)_
* `.vscode/`: VSCode configuration files

<!-- <<Stencil::Block(directoryStructureCustom)>> -->

<!-- <</Stencil::Block>> -->

If you need more context, you can find more information in `docs/` directory. If the directory does not exist, ignore this line.

## References table

| Description | Reference |
|----|----|
| Stencil commands | [docs/stencil-commands.md](./docs/stencil-commands.md) |
<!-- <<Stencil::Block(referencesTableCustom)>> -->

<!-- <</Stencil::Block>> -->

<!--- -->
<!--- * Run `make fmt` to format project. -->
<!--- * Run `make lint` to run linters on project's code. -->


<!-- <<Stencil::Block(agentsReferencesCustom)>> -->

<!-- <</Stencil::Block>> -->

## Boundaries

### Always


<!-- <<Stencil::Block(agentsBoundariesAlwaysCustom)>> -->

<!-- <</Stencil::Block>> -->

### Ask


<!-- <<Stencil::Block(agentsBoundariesAskCustom)>> -->

<!-- <</Stencil::Block>> -->

### Never


<!-- <<Stencil::Block(agentsBoundariesNeverCustom)>> -->

<!-- <</Stencil::Block>> -->

## Other

<!-- <<Stencil::Block(agentsOtherCustom)>> -->

<!-- <</Stencil::Block>> -->
