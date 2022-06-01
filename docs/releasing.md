# Releasing a stencil-golang Service

Releasing is configured to be done with a combination of [semantic-release](https://github.com/semantic-release/semantic-release) and [goreleaser](https://goreleaser.com/).

semantic-release is used to configure how version tags are created. goreleaser is used to configure how the release is built for CLIs, while semantic-release actually creates the github releases and uploads the artifacts. For services, just semantic-release is used and Docker images are built on tag creation in CI.

## semantic-release Rules

semantic-release will create a tag based on the PR title, this is done via [conventional commit](https://www.conventionalcommits.org/en/v1.0.0/).

A conventional commit generally has the following format: `type(optionalScope): short description`

**Examples:**

 * feat: support multiple users
 * feat(users): add multiple user support

Let’s look at each of the different sections of a conventional commit:

### type

A type controls the what is released, or not released. Generally a type should be specific to the changes in the PR, but when in doubt you can always select one that has the releasing behaviour you want.

#### Major Release (vX.0.0)

* `BREAKING CHANGE` - Breaks existing functionality.
* `type!` - shorthand for BREAKING CHANGE, use any other type below with a ! at the end.

**Examples:**

 * `feat!(scope): break all the things`
 * `feat!: break allllllll the things`

#### Minor Release (v0.X.0)

 * `feat` - a feature, this should be something that adds to the service and is end user facing, this should not be a a breaking change.

#### Patch Release (v0.0.X)

 * `fix` - a fix to an existing feature in the service. Important: This should not be related to CI/CD, build, etc. See below for those.
 * `revert` - reverts a previous commit, e.g. an accidental breaking change
 * `perf` - a performance modification, does not change existing functionality. Use feat if net-new functionality is added.

#### No Release

 * `refactor` - changes existing code, a catch-all for changes not related to performance
 * `ci` - a modification related to the CI/CD system of the service. This does not trigger a release.
 * `build` - a modification related to the build of the system, e.g. docker file, scripts building it, etc. This does not trigger a release.
 * `docs` - a modification to the documentation of the service, e.g. README. This does not trigger a release
 * `style` - a pure style change to existing source code (e.g. whitespace formatting)
 * `test` - add missing tests or modify existing tests
 * `chore` - a misc, catch-all, change that doesn’t modify source code.  This does not trigger a release.

### scope

A scope is a useful way to separate changes, and identify them in a changelog. This is not required, and is loosely defined based on the project.

**Examples:**

 * `feat(users): added multiple users modified files in a internal/reactor/users_controller.go`
 * `fix(http): properly bind to config port modified the http server code in internal/reactor/httpservice.go`

## Releasing in CI

With consideration to the above rules, by default releasing is done in CI. Currently this is just in CircleCI. CircleCI is configured to run a `release` job in dryrun mode on a PR. This runs `semantic-release` which reads the `.releaserc.yaml`. This file is created by the [stencil-base](https://github.com/getoutreach/stencil-base/blob/main/templates/.releaserc.yaml.tpl) module and contains the definitions for releasing. It can be thought of as a secondary tool for defining the release process.

On merge into a HEAD branch (`main`) this job is no longer ran in dry run mode and tags/releases are created using the `semantic-release` tool. This, by default, is done with the releasing rules defined above and a changelog generated from them. When the tag is created, a docker image build/push is triggered from the created tag.
