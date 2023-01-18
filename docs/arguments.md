# Arguments

Below is a list of all of the arguments that `stencil-golang` supports. Other options from [stencil-base](TODO) are also used here.

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

A list of gRPC clients to generate for this application. Requires `grpc` to be in the `serviceActivities` list.

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

## `terraform.datadog.http.latency.count.highCount`

**Type**: `number`
**Default**: `1000`

Overrides the high count threshold in the `http_latency_high` terraform module in `monitoring/datadog.tf`.

## `terraform.datadog.http.latency.thresholds.lowTraffic`

**Type**: `number`
**Default**: `2`

Overrides the low traffic threshold in the `http_latency_high` terraform module in `monitoring/datadog.tf`.

## `terraform.datadog.http.latency.thresholds.highTraffic`

**Type**: `number`
**Default**: `2`

Overrides the high traffic threshold in the `http_latency_high` terraform module in `monitoring/datadog.tf`.

## `terraform.datadog.monitoring.argocd.appHealth.notify`
**Type**: `bool`
**Default**: `false`

Enable/Disable Datadog P2 notification for ArgoCD Application Health

## `terraform.datadog.monitoring.argocd.syncStatus.notify`
**Type**: `bool`
**Default**: `false`

Enable/Disable Datadog P2 notification for ArgoCD Sync Status

## `terraform.datadog.monitoring.argocd.appHealth.evaluationWindow`
**Type**: `string`
**Default**: `last_15m`

Evaluation time frame for Datadog to evaluate the ArgoCD Application Health monitor. 

## `terraform.datadog.monitoring.argocd.syncStatus.evaluationWindow`
**Type**: `string`
**Default**: `last_15m`

Evaluation time frame for Datadog to evaluate the ArgoCD Sync Status monitor. 
