# Module Hooks

stencil-golang exposes a few module hooks to allow for integration with other modules. These docs will go over them at a _highlevel_, but note this is **not** and exhaustive list of hooks or how to use them. For more information it's suggested to look at the hooks in context of the file you're trying to modify.

### `go_modules`

**Type**: `{ name string, version string }`

**File**: `_helpers.tpl`

Add a dependency to this service. This dependency will be ignored by dependency management tools like `dependabot` in favor of the dependency specified in `go_modules`.

```yaml
{{ stencil.AddToModuleHook "github.com/getoutreach/stencil-golang" (list (dict "name" "a" "version "1.0.0")) }}
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

**Type**: `[key, value]`

**File**: `.vscode/private.env.tpl`

Environment variables to write out to `private.env` for VSCode to use while running tests.

```yaml
{{ stencil.AddToModuleHook "github.com/getoutreach/stencil-golang" (list (list "MY_ENV_VAR" "my-value")) }}
```

### `api.Service`

**Type**: `string`

**File**: `api/api.go.tpl`

Extra interface methods to add to the `Service` interface.

```tpl
{{ $myInterface := "MyServiceMethod(ctx context.Context) error" }}
{{ stencil.AddToModuleHook "github.com/getoutreach/stencil-golang" (list $myInterface) }}
```

### `api.proto.message`

**Type**: `string`

**File**: `api/api.proto.tpl`

Extra message types to add to the `api.proto` file.

**Note**: New lines are supported.

```tpl
{{ $myMessage := "message MyMessage { string my_field = 1; }" }}
{{ stencil.AddToModuleHook "github.com/getoutreach/stencil-golang" (list $myMessage) }}
```

### `api.proto.service`

**Type**: `string`

**File**: `api/api.proto.tpl`

Extra service rpcs to add to the `api.proto` file.

```tpl
{{ $myService := "rpc MyMethod (MyMessage) returns (MyMessage) {}" }}
{{ stencil.AddToModuleHook "github.com/getoutreach/stencil-golang" (list $myService) }}
```

### `mixins`

**Type**: `string`

**File**: `deployments/appname/app.jsonnet.tpl`

Extra mixin files in `deployments/appname/mixins` to include in the jsonnet deployments.

```tpl
# deployments/appname/mixins/my-mixin.jsonnet
{{ $myMixin := "my-mixin" }}
{{ stencil.AddToModuleHook "github.com/getoutreach/stencil-golang" (list $myMixin) }}
```
