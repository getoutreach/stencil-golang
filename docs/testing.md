# Writing Tests

stencil-golang supports three methods of writing tests:

 * unit tests
 * e2e tests

The E2E framework can be thought of as running in a live environment with dependencies running. This is the preferred method of writing feature tests. Unit tests run with no dependencies and are good for testing isolated components of logic.

## Linting

Linting is considered part of our testing framework. Complete information about linting can be found in the [linting guide](./linting.md).

## Writing a Unit Test

Writing a unit test is simple, we provide nothing on top of the standard go testing conventions. For brevity it's as simple as adding a `<name>_test.go` file for the file that you want to test. Then adding a function with the format of: `TestThingIWantToTest(t *testing.T)`.

These are automatically executed during `make test`.

## Writing an E2E Test

An E2E test is still powered by the normal go testing framework, but we provide a few extra changes. E2E tests should go into the `e2e` folder in the root of the repository, creating it if it doesn't already exist. The reasoning behind this is that E2E tests are _not_ scoped to a single file / package and thus do not belong within the normal structure.

An E2E test is a basic test file with the standard format, but currently requires a go build tag. This go build tag is `//go:build or_e2e`.

These are executed with `make e2e` via the [e2e runner](https://github.com/getoutreach/devbase/tree/main/e2e). The e2e runner provisions a [devenv](https://github.com/getoutreach/devenv) instance on your local machine, or reuses an existing one if one is already running (with a warning because that is potentially not-reproducible). In CI environments, the e2e runner will also provision a fresh devenv for testing. These tests are currently ran outside of the devenv using [localizer](https://github.com/getoutreach/localizer). These will be shortly ran inside of the cluster which will be the preferred method of running these tests.
