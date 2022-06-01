# stencil-golang

stencil-golang is a stencil module for Golang applications. Primarily designed for service development, it also supports CLIs and libraries. The main goal is to provide a simple, yet powerful, way to build and deploy services as easily as possible.

## What's Included

 * CircleCI (via [stencil-circleci](https://github.com/getoutreach/stencil-circleci))
 * E2E Testing Framework
 * Kubernetes Manifests (via [kubecfg](https://github.com/anguslees/kubecfg))
 * Kubernetes [devenv](https://github.com/getoutreach/devenv) support
 * Docker
 * Releasing / Versioning via [semantic-release](https://github.com/semantic-release/semantic-release)
 * Service Activity framework enabling an easy extension framework.
 * Vault integration

## Requirements

There's a few requirements for using `stencil-golang` at the moment.

 * Github, currently we only support Github for tooling. Other VCS providers may work but they are not supported.
 * Kubernetes, we welcome contributions to support other deployment toolchains though!
 * CircleCI, we don't support other CI/CD providers currently but we're open to contributions and likely may provide support for Github Actions soon.

## Using stencil-golang

Using `stencil-golang` requires `stencil` to be installed. For information on how to install `stencil` see the [docs](https://engineering.outreach.io/stencil).

Once you have stencil, you'll need to create a `service.yaml` in a directory:

```bash
$ mkdir my-application; cd my-application
$ touch service.yaml
```

From there you can open up the `service.yaml` with your favorite editor and insert the following:

```yaml
# name should equal the name of your repository
name: my-application
modules:
# This inserts stencil-golang to be used in the stencil invocation
- name: github.com/getoutreach/stencil-golang
# For a complete list of arguments, see the arguments.md file in the docs.
arguments: {}
```

From there you can run `stencil` and you'll get a basic library. You can change this to a service by setting `arguments.service` to `true`.

## More Information

Each of the `.md` files here have more information on the internals of `stencil-golang` and are highly recommended if you're looking for more information!
