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
