# stencil-golang

<!-- <<Stencil::Block(customGeneralInformation)>> -->

<!-- <</Stencil::Block>> -->

## Prerequisites

<!-- <<Stencil::Block(customPrerequisites)>> -->

<!-- <</Stencil::Block>> -->

## Building and Testing

This project uses devbase, which exposes the following build tooling: [devbase/docs/makefile.md](https://github.com/getoutreach/devbase/blob/main/docs/makefile.md)

<!-- <<Stencil::Block(customBuildingAndTesting)>> -->

<!-- <</Stencil::Block>> -->

### Replacing a Remote Version of the Package with Local Version

_This is only applicable if this repository exposes a public package_.

If you want to test a package exposed in this repository in a project that uses it, you can
add the following `replace` directive to that project's `go.mod` file:

```
replace github.com/getoutreach/stencil-golang => /path/to/local/version/stencil-golang
```

**_Note_**: This repository may have postfixed it's module path with a version, go check the first
line of the `go.mod` file in this repository to see if that is the case. If that is the case,
you will need to modify the first part of the replace directive (the part before the `=>`) with
that postfixed path.

### Linting and Unit Testing

You can run the linters and unit tests with:

```bash
make test
```

This repository uses snapshots to make sure that the generated files are what we expect to be
rendered by Stencil. When you run `make test` locally, it will update the snapshots. Please make
sure to review those changes and commit them before making a pull request, as CI will fail if
said snapshots have not been updated appropriately.
