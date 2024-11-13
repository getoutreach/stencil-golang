# Module Hooks

**Note**: Stencil module hooks are documented in the [module docs](https://engineering.outreach.io/stencil/reference/template-module/#module-hooks).

stencil-golang exposes a few module hooks to allow for integration with other modules. These docs will go over them at a _highlevel_, but note this is **not** and exhaustive list of hooks or how to use them. For more information it's suggested to look at the hooks in context of the file you're trying to modify.

### `go_modules`

**Type**: `{ name string, version string }`

**File**: `_helpers.tpl`

Add a dependency to this service. This dependency will be ignored by dependency management tools like `dependabot` in favor of the dependency specified in `go_modules`.

```yaml
{{- define "deps" -}}
- name: a-module
  version: 1.0.0
{{- end -}}
{{ stencil.AddToModuleHook "github.com/getoutreach/stencil-golang" "go_modules" (stencil.ApplyTemplate "deps" | fromYaml) }}
```

### `js_modules`

**Type**: `{ name string, version string }`

**File**: `_helpers.tpl`

Equivalent `go_modules` but for JavaScript (node).

### `js_modules_dev`

**Type**: `{ name string, version string }`

**File**: `_helpers.tpl`

Equivalent `go_modules` but for JavaScript (node), dev dependencies.

### `vaultSecrets`

**Type**: `[]string`

**File**: `deployments/appname/app.jsonnet.tpl`

Adds Vault secret paths to be pulled within the deployment manifests and created in Kubernetes.

```tpl
{{ stencil.AddToModuleHook "github.com/getoutreach/stencil-golang" "vaultSecrets" (list "path/to/secret") }}
```

### `private.env.envVars`

**Type**: `map[string]interface{}`

**File**: `.vscode/private.env.tpl`

Environment variables to write out to `private.env` for VSCode to use while running tests.

```yaml
{
  {
    stencil.AddToModuleHook "github.com/getoutreach/stencil-golang" (list (dict "MY_ENV_VAR" "my-value")),
  },
}
```

### `api.Service`

**Type**: `string`

**File**: `api/api.go.tpl`

Extra interface methods to add to the `Service` interface.

```tpl
{{ $myInterface := "MyServiceMethod(ctx context.Context) error" }}
{{ stencil.AddToModuleHook "github.com/getoutreach/stencil-golang" "api.Service" (list $myInterface) }}
```

### `api.proto.message`

**Type**: `string`

**File**: `api/api.proto.tpl`

Extra message types to add to the `api.proto` file.

**Note**: New lines are supported.

```tpl
{{ $myMessage := "message MyMessage { string my_field = 1; }" }}
{{ stencil.AddToModuleHook "github.com/getoutreach/stencil-golang" "api.proto.message" (list $myMessage) }}
```

### `api.proto.service`

**Type**: `string`

**File**: `api/api.proto.tpl`

Extra service rpcs to add to the `api.proto` file.

```tpl
{{ $myService := "rpc MyMethod (MyMessage) returns (MyMessage) {}" }}
{{ stencil.AddToModuleHook "github.com/getoutreach/stencil-golang" "api.proto.service" (list $myService) }}
```
### `main.dependencies`

**Type**: ``map[string]interface{}``

**File**: `main.go.tpl`

Additional dependencies to add to the `main.go` file.

```tpl
{{  stencil.AddToModuleHook "github.com/getoutreach/stencil-golang" "main.dependencies"
        (list
            (dict "count" "int")
        )
    }}
```

### `http/*`

**Type**: `string`

**File**: `internal/appName/http/handler.go.tpl`

Insert to different parts for extension of `handler.go`

- `http/extraComments` add extra comment in top of the file
- `http/extraStandardImports` add extra standard imports
- `http/additionalImports` add extra other imports
- `http/extraRoutes` add extra handlers for routing
- `http/extraFuncs` add extra functions for routing's usages

```tpl
{{  stencil.AddToModuleHook "github.com/getoutreach/stencil-golang" "http/xxxx"
        (stencil.applyTemplate "<template-name>")
    }}
```

### `internal/rpc/*`

**Type**: `string`

**File**: `internal/appName/rpc/rpc.go.tpl`

Insert to different parts for extension of `rpc.go`

- `internal/rpc/extraComments` add extra comment in top of the file
- `internal/rpc/extraStandardImports` add extra standard imports
- `internal/rpc/additionalImports` add extra non-standard imports
- `internal/rpc/grpcServerOptionInit` add extra init statements by modules
- `internal/rpc/grpcServerOptions` add extra options by modules
- `internal/rpc/additionalGRPCRPCS` add extra gRPC RPCs injected by modules
- `internal/rpc/additionalDefaultHandlers` add extra functions

```tpl
{{  stencil.AddToModuleHook "github.com/getoutreach/stencil-golang" "internal/rpc/xxxx"
        (stencil.applyTemplate "<template-name>")
    }}
```

### `mixins`

**Type**: `string`

**File**: `deployments/appname/app.jsonnet.tpl`

Extra mixin files in `deployments/appname/mixins` to include in the jsonnet deployments.

```tpl
# deployments/appname/mixins/my-mixin.jsonnet
{{ $myMixin := "my-mixin" }}
{{ stencil.AddToModuleHook "github.com/getoutreach/stencil-golang" "mixins" (list $myMixin) }}
```

### `Dockerfile.afterBuild`

**Type**: `string`

**File**: `deployments/appname/Dockerfile.tpl`

Extra commands to run after the build stage in the Dockerfile.

```tpl
{{ $myCommand := "RUN echo 'hello world'" }}
{{ stencil.AddToModuleHook "github.com/getoutreach/stencil-golang" "Dockerfile.afterBuild" (list $myCommand) }}
```

### `app.config.jsonnet/config`

**Type**: `string`

**File**: `deployments/appname/app.config.jsonnet.tpl`

Extra configuration jsonnet files to merge into the application config.

```tpl
# deployments/appname/configs/my-config.jsonnet
{{ $myConfig := "my-config" }}
{{ stencil.AddToModuleHook "github.com/getoutreach/stencil-golang" "app.config.jsonnet/config" (list $myConfig) }}
```

### `devspace.binarySyncDevPatches`

**Type**:

```yaml
[
  {
    op: string
    path: string
    value: [ key: value ]
  }
]
```

**File**: `devspace.yaml.tpl`

Extra [devspace patches](https://www.devspace.sh/docs/configuration/profiles/patches)
to use when using the binary sync feature of `devenv`.

Example:

```tpl
{{- define "syncFooBarFolderForBinarySync" }}
- op: add
  path: dev.app.sync
  value:
    path: ./foo/bar:${DEV_CONTAINER_WORKDIR}/foo/bar
    waitInitialSync: true
    initialSync: mirrorLocal
    disableDownload: true
    printLogs: true
{{- end }}

{{ stencil.AddToModuleHook "github.com/getoutreach/stencil-golang" "devspace.binarySyncDevPatches" (stencil.ApplyTemplate "syncFooBarFolderForBinarySync" | fromYaml) }}
```

### `devspace.profiles`

**Type**:

```
{
   name: string,
   description: string,
   activation:
      env: [ key: value ]
      vars: [ key: value ]
   patches:
      [
        {
          op: string
          path: string
          value: [ key: value ]
        }
      ]
```

**File**: `devspace.yaml.tpl`

Extra [devspace profiles](https://www.devspace.sh/docs/5.x/configuration/profiles/basics) to merge into the devspace.yaml config.

```tpl
{{- define "ingestTerminalDevspaceProfile" }}
- name: {{ .Config.Name }}-ingest-terminal
  description: Allows for running ingest in --with-terminal mode
  activation:
    - env:
        DEVENV_DEV_DEPLOYMENT_PROFILE: deployment__{{ .Config.Name }}-ingest
        DEVENV_DEV_TERMINAL: "true"
  patches:
    - op: replace
      path: dev.terminal.labelSelector
      value:
        app: {{ .Config.Name }}-ingest
{{- end }}

{{ stencil.AddToModuleHook "github.com/getoutreach/stencil-golang" "devspace.profiles" (stencil.ApplyTemplate "ingestDevspaceProfile" | fromYaml) }}
```

### `devspace.sync`

**Type**:

```
{
  name: string,
  labelSelector: string,
  namespace: string,
  localSubPath: string,
  containerPath: string,
  excludePaths: [ string ]
}
```

**File**: `devspace.yaml.tpl`

Extra devspace sync to merge into a devspace.yaml config.

```
{{- define "testSync"}}
    - name: test
      labelSelector: ${DEVENV_DEPLOY_LABELS}
      namespace: ${DEVENV_DEPLOY_NAMESPACE}
      localSubPath: ./
      containerPath: ${DEV_CONTAINER_WORKDIR}
      excludePaths:
        - bin
        - ./vendor
{{- end }}

{{ stencil.AddToModuleHook "github.com/getoutreach/stencil-golang" "devspace.profiles" (stencil.ApplyTemplate "testSync" | fromYaml) }}
```

### `devspace.ports`

**Type**: `string`

**File**: `devspace.yaml.tpl`

Extra ports that should be forwarded while `devspace dev` is running

```tpl
# devspace.ports
{{- stencil.AddToModuleHook "github.com/getoutreach/stencil-golang" "devspace.ports" (list "4000") }}
```

### `Makefile.commands`

**Type**: `string`

**File**: `Makefile`

Extra commands to add to the root Makefile

```tpl
{{- define "run.rover" }}
## run-rover:           merges shared and specific schemas and runs rover-cli
.PHONY: run-rover
run-rover:
	cat internal/graphql/schema/shared.graphql > internal/graphql/generated/schema.graphql
	cat internal/graphql/schema/schema.graphql >> internal/graphql/generated/schema.graphql
	rover dev --router-config config/apollo.yaml --name $appName --url http://localhost:4000/graphql --schema internal/graphql/generated/schema.graphql
{{- end }}

{{- stencil.AddToModuleHook "github.com/getoutreach/stencil-golang" "Makefile.commands" (list (stencil.ApplyTemplate "run.rover")) }}
```

### `monitoring.slos`

**Type**: `string`

**File**: `monitoring/slos.tf`

Extra SLO teraform definitions.

```
{{- define "grpc-slo"}}
resource "datadog_service_level_objective" "grpc_p99_latency" {
  name        = "{{ .Config.Name | title }} GRPC P99 Latency"
  type        = "monitor"
  description = "Keeping track of P99 latency commitments for all {{ .Config.Name | title }} GRPC requests in aggregate, for production bentos only."
  tags = local.ddTags
  monitor_ids = [module.grpc_latency_high.high_traffic_id]
  groups = [
    {{- $bentos := extensions.Call "github.com/getoutreach/stencil-discovery.Bentos" (stencil.Arg "deployment.environments") (stencil.Arg "deployment.serviceDomains") }}
    {{- range $b := $bentos }}
    "kube_namespace:{{ stencil.ApplyTemplate "goPackageSafeName" }}--{{ $b.name }}",
    {{- end }}
  ]
  thresholds {
    timeframe = "7d"
    target = 99.9
    warning = 99.95
  }
}
{{- end }}


{{- stencil.AddToModuleHook "github.com/getoutreach/stencil-golang" "monitoring.slos"
  (list (stencil.ApplyTemplate "grpc-slo"))
}}
```

### `vscode/additional-extensions`

**Type**: `string`

**File**: `.vscode/extensions.json`

This hook allows you to add more recommended extensions for the workspace in VSCode. These extensions are suggested when a developer opens the workspace in VSCode.

```tpl
{{- define "extensions" -}}
"somekittens.hot-dog-stand",
{{- end }}

{{ stencil.AddToModuleHook "github.com/getoutreach/stencil-golang" "vscode/additional-extensions"
  (list
    (stencil.ApplyTemplate "extensions")
  )
}}
```
