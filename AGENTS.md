# stencil-golang

Ignore lines containing "Stencil::Block"; they are areas in your generated code that you’d like to persist across runs and are repository specific. These lines are for template generator and do not contain agent instructions.

## Description

<!-- <<Stencil::Block(agentsProjectOverview)>> -->

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

# mise
mise tasks ls # List all tasks available through mise.
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
| Stencil commands | [docs/stencil-commands.md](./docs/agents/stencil-commands.md) |
| Mise commands | [docs/mise-commands.md](./docs/agents/mise-commands.md) |
| Internal Go idioms | [webpage](https://outreach-io.atlassian.net/wiki/spaces/EN/pages/1124335785/Go+idioms) |
| Idiomatic Go practices | [webpage](https://dmitri.shuralyov.com/idiomatic-go) |
<!-- <<Stencil::Block(referencesTableCustom)>> -->

<!-- <</Stencil::Block>> -->

<!--- -->
<!--- * Run `make fmt` to format project. -->
<!--- * Run `make lint` to run linters on project's code. -->


<!-- <<Stencil::Block(agentsReferencesCustom)>> -->

<!-- <</Stencil::Block>> -->

## Boundaries

### Always

- Run `make fmt` after making code changes
- Run `make lint` after making code changes and fix any issues
- Keep functions small and single-purpose
- Check `stencil.lock` to determine file ownership before modifying generated files
- Prefer running `mise` tasks over make targets when available
- Run `go mod tidy` after adding or removing Go dependencies
- Run `make gogenerate` after modifying protobuf definitions or interfaces with generated code
- Follow idiomatic Go error handling (return errors, don't panic)
- Use structured logging (e.g., log.WithError(err).Error(...)) instead of fmt.Printf
- Add context to errors using `fmt.Errorf("...: %w", err)`


<!-- <<Stencil::Block(agentsBoundariesAlwaysCustom)>> -->

<!-- <</Stencil::Block>> -->

### Ask

- Write unit tests for new functions and bug fixes
- Before deleting or significantly refactoring a package or file
- Before changing public API signatures (exported functions, types, or interfaces)
- Before adding new external dependencies
- Before bumping major versions of dependencies
- Before changing database schema or migration files // maybe different module?


<!-- <<Stencil::Block(agentsBoundariesAskCustom)>> -->

<!-- <</Stencil::Block>> -->

### Never

- Commit secrets, credentials, API keys, or tokens
- Force-push to main or protected branches
- Disable or skip linters/tests to make a build pass
- Ignore or swallow errors silently (e.g., _ = someFunc() without justification)
- Add TODO or FIXME comments without a linked issue or explanation
- Use `panic()` in production code paths


<!-- <<Stencil::Block(agentsBoundariesNeverCustom)>> -->

<!-- <</Stencil::Block>> -->

## Other

<!-- <<Stencil::Block(agentsOtherCustom)>> -->

<!-- <</Stencil::Block>> -->
