# Arguments

Below is a list of all of the arguments that `stencil-golang` supports.

## `service`

**Type**: `bool`
**Default**: `false`

Indicates that this application is a service and that the [service-activity](./service-activity.md) framework should be built.

```yaml
service: true
```

## `serviceActivities`

**Type**: `list`
**Default**: `[]`
**Options**: `['grpc', 'http', 'kafka']`

A list of service activities that should be generated. Requires `service` to be set to `true`.

```yaml
serviceActivities:
  - grpc
  - http
  - kafka
```

## `commands`

**Type**: `list`
**Default**: `[]`

A list of CLIs to generate for this application.

```yaml
commands:
  - name: my-cli
```

## `grpcClients`

**Type**: `list`
**Default**: `[]`
**Options**: `['node', 'ruby']`

A list of gRPC clients to generate for this application.

**Note**: A golang client is _always_ created.

```yaml
grpcClients:
- node
- ruby
```

## `reportingTeam`

**Type**: `string`
**Default**: `""`

Team to set as the [CODEOWNER](https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/about-code-owners) of this repository.

```yaml
reportingTeam: "fnd-dtss"
```

## `kubernetes.groups`

**Type**: `list`
**Default**: `[]`

A list of Kubernetes Custom Resource groups to generate. Automatically enables a Kubernetes service activity to process it.

```yaml
kubernetes:
  groups:
    - group: databases.outreach.io
      version: v1
      package: database
      resources:
        - kind: DatabaseCluster
          generate:
            # Generate a mutating webhook for the CRD
            webhook: false
            # Generate a controller for the CRD
            controller: true
```

## `lintroller`

**Type**: `string`
**Default**: `platinum`

The level of rules to apply for the [lintroller](https://github.com/getoutreach/lintroller) linter.

## `vaultSecrets`

**Type**: `list`
**Default**: `[]`

A list of Vault key paths to use for this service. These secrets will be pulled on deployment time and stored in a Kubernetes secret with the `basename` of the path.
