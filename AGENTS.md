# AI Agent instructions

Ignore lines containing "Stencil::Block"; they are templates. Purpose: concise rules and actionable workflows for AI-assisted contributors.

## Project purpose

<!-- <<Stencil::Block(projectPurpose)>> -->
This project serves as a base for all projects using `stencil` templating and Golang programming language.
<!-- <</Stencil::Block>> -->

## Directory structure
* `templates/`: Templates for generating project files, such as `AGENTS.md.tpl` for the AGENTS.md file. Used in stencil-modules to define the structure and content of generated files.
* `scripts/`: internal development shell scripts _(**deprecated**, prefer to use `mise` tasks when appropriate)_
* `.vscode/`: VSCode configuration files

* **./service.yaml**: File used as configuration for `stencil` program containing additional arguments and stencil modules to use
* **./stencil.lock**: File used as record for:
  1. What modules where used and their version
  2. What module owns which file
  3. If a file is not listed here, the owner is current repository

If you need more context, you can find more information in `docs/` directory. If the directory does not exist, ignore this line.

## Components
What are components? (golang)

<!-- <<Stencil::Block(agentsComponentsCustom)>> -->

<!-- <</Stencil::Block>> -->

## Other
Other agent information (golang)

<!-- <<Stencil::Block(agentsOtherCustom)>> -->

<!-- <</Stencil::Block>> -->
