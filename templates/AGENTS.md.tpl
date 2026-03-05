{{- file.Skip "Virtual file for AGENTS.md module hooks" }}

{{- define "golangDirectoryStructure" }}
* `api/`: API definitions, such as protobuf files and OpenAPI specifications
* `bin/`: generated project executables.
* `cmd/`: main CLI Go code
* `deployments/`: Container publishing configuration
* `internal/`: internal (non-public) Go packages
* `scripts/`: internal development shell scripts _(**deprecated**, prefer to use `mise` tasks when appropriate)_
* `testdata/`: test fixtures and other test data
* `.vscode/`: VSCode configuration files
{{- end }}

{{ stencil.AddToModuleHook "github.com/getgolang/stencil-base" "directoryStructure" (list (stencil.ApplyTemplate "golangDirectoryStructure")) }}

{{- define "golangComponents" }}
What are components? (golang)
{{- end }}

{{ stencil.AddToModuleHook "github.com/getgolang/stencil-base" "agentsComponents" (list (stencil.ApplyTemplate "golangComponents")) }}

{{- define "golangAgentsOther" }}
Other agent information (golang)
{{- end }}

{{ stencil.AddToModuleHook "github.com/getgolang/stencil-base" "agentsOther" (list (stencil.ApplyTemplate "golangAgentsOther")) }}


# {{- define "golangQuickStart" }}
# * Format modified files and imports:

# ```bash
# gofmt -w ./... && goimports -w ./...
# ```

# * Run linters (local):

# ```bash
# PATH="$BASH5_PATH:$PATH" make lint
# ```

# * Run tests:

# ```bash
# PATH="$BASH5_PATH:$PATH" make test
# ```
# {{- end }}

# {{ stencil.AddToModuleHook "github.com/getgolang/stencil-base" "projectQuickStart" (list (stencil.ApplyTemplate "golangQuickStart")) }}

# {{- define "golangLintingWorkflow" }}
# 1. Format: `gofmt -w ./...`
# 2. Fix imports: `goimports -w ./...`
# 3. Run all linters: `PATH="$BASH5_PATH:$PATH" make lint`
# 4. Fix all reported issues; re-run until clean.

# Required confirmation (paste into PR description or task completion):

# ```
# Linting Status:
# ✅ Ran: PATH="$BASH5_PATH:$PATH" make lint
# ✅ Result: All linters passing (or list of remaining issues)
# ✅ All errors fixed
# ```

# Notes:
# - If a linter flags a style/formatting problem, fix the source not the linter config.
# - If you think a lint rule should be changed, open a PR to central config and request revie
# w.

# **If you do not run linters and confirm the results, you have NOT completed the task.**

# #### When to Run Linters

# 1. Immediately after writing a new file
# 2. Immediately after modifying an existing file
# 3. Before claiming any task is complete
# 4. When you see a linter error, fix it immediately - don't defer it

# #### Handling Linter Violations

# When the linter reports any issue:

# 1. **Read the error message carefully** - Understand what's being reported and why
# 2. **Fix the root cause** - Don't just suppress warnings; address the underlying issue
# 3. **Re-run the linter** - Verify the fix resolved the issue completely
# 4. **Never skip linting** - Even if the code compiles, linters catch important issues

# **If you don't understand a linter error:**

# - Research the specific linter rule to understand its purpose
# - Ask the user for clarification if needed
# - NEVER ignore or suppress the error without understanding it

# #### DO NOT:

# - ❌ Skip linters because "the code compiles"
# - ❌ Skip linters because "it's similar to code I wrote before"
# - ❌ Skip linters because "they're slow"
# - ❌ Wait for the user to find linter errors
# - ❌ Fix linter errors one-by-one as the user reports them

# **Zero tolerance: Run linters. Always. This is wasting the user's time otherwise.**
# {{- end }}

# {{ stencil.AddToModuleHook "github.com/getgolang/stencil-base" "projectLintingWorkflow" (list (stencil.ApplyTemplate "golangLintingWorkflow")) }}

# {{- define "golangCriticalRules_MandatoryLintingWorkflow" }}
# **YOU MUST RUN LINTERS BEFORE CLAIMING ANY CODING TASK IS COMPLETE.**

# Skipping linters wastes the user's time by forcing them to manually find errors that linters would catch automatically.

# #### Completion Checklist

# After writing or modifying ANY Go code:

# ```bash
# # 1. Format the code
# gofmt -w <modified-files>
# goimports -w <modified-files>

# # 2. RUN LINTERS (DO NOT SKIP THIS)
# cd $MONOREPO_PATH
# PATH="$BASH5_PATH:$PATH" make lint

# # This runs ALL linters: golangci-lint, lintroller, shellcheck, eslint, buf, tflint, etc.

# # 3. Fix ALL linter errors immediately
# # 4. Re-run linters until output is clean
# # 5. Only then is the task complete
# ```

# #### Required Confirmation

# At the end of every coding task, you MUST include:

# ```
# Linting Status:
# ✅ Ran: PATH="$BASH5_PATH:$PATH" make lint
# ✅ Result: All linters passing (or list of remaining issues)
# ✅ All errors fixed
# ```

# **If you do not run linters and confirm the results, you have NOT completed the task.**

# #### When to Run Linters

# 1. Immediately after writing a new file
# 2. Immediately after modifying an existing file
# 3. Before claiming any task is complete
# 4. When you see a linter error, fix it immediately - don't defer it

# #### Handling Linter Violations

# When the linter reports any issue:

# 1. **Read the error message carefully** - Understand what's being reported and why
# 2. **Fix the root cause** - Don't just suppress warnings; address the underlying issue
# 3. **Re-run the linter** - Verify the fix resolved the issue completely
# 4. **Never skip linting** - Even if the code compiles, linters catch important issues

# **If you don't understand a linter error:**

# - Research the specific linter rule to understand its purpose
# - Ask the user for clarification if needed
# - NEVER ignore or suppress the error without understanding it

# #### DO NOT:

# - ❌ Skip linters because "the code compiles"
# - ❌ Skip linters because "it's similar to code I wrote before"
# - ❌ Skip linters because "they're slow"
# - ❌ Wait for the user to find linter errors
# - ❌ Fix linter errors one-by-one as the user reports them

# **Zero tolerance: Run linters. Always. This is wasting the user's time otherwise.**
# {{- end }}

# {{ stencil.AddToModuleHook "github.com/getgolang/stencil-base" "projectCriticalRules_MandatoryLintingWorkflow" (list (stencil.ApplyTemplate "golangCriticalRules_MandatoryLintingWorkflow")) }}

# {{- define "golangCriticalRules_MandatoryTestingWorkflow" }}
# **YOU MUST RUN TESTS BEFORE CLAIMING ANY CODING TASK IS COMPLETE.**

# Skipping tests wastes the user's time by allowing broken code to be committed. If tests fail, you have NOT completed the task.

# #### Testing Checklist

# After writing or modifying ANY code:

# ```bash
# # Run the full test suite
# cd $MONOREPO_PATH
# PATH="$BASH5_PATH:$PATH" make test

# # Fix ALL test failures immediately
# # Re-run tests until all tests pass
# # Only then is the task complete
# ```

# #### Required Confirmation

# At the end of every coding task, you MUST include:

# ```
# Testing Status:
# ✅ Ran: PATH="$BASH5_PATH:$PATH" make test
# ✅ Result: All tests passing (or list of failures with fixes)
# ✅ All test failures fixed
# ```

# **If you do not run tests and confirm all tests pass, you have NOT completed the task.**

# #### When to Run Tests
# 1. After writing new code or modifying existing code
# 2. Before claiming any task is complete
# 3. After fixing linter errors (linting can sometimes break tests)
# 4. When you see a test failure, fix it immediately - don't defer it

# #### Handling Test Failures

# When tests fail:

# 1. **Read the failure message carefully** - Understand what's failing and why
# 2. **Fix the root cause** - Don't just update tests to pass; fix the actual issue
# 3. **Re-run the tests** - Verify the fix resolved the failure completely
# 4. **Never skip failing tests** - Even if "most tests pass", all tests must pass

# **If you don't understand a test failure:**
# - Read the test code to understand what it's validating
# - Check if your changes broke existing functionality
# - Ask the user for clarification if needed
# - NEVER ignore or skip failing tests

# #### DO NOT:
# - ❌ Skip tests because "the code looks correct"
# - ❌ Skip tests because "they're slow"
# - ❌ Skip tests because "only one test is failing"
# - ❌ Wait for the user to find test failures
# - ❌ Assume tests will pass without running them

# **Zero tolerance: Run tests. Always. Broken tests mean broken code.**
# {{- end }}

# {{ stencil.AddToModuleHook "github.com/getgolang/stencil-base" "projectCriticalRules_MandatoryTestingWorkflow" (list (stencil.ApplyTemplate "golangCriticalRules_MandatoryTestingWorkflow")) }}

# {{- define "golangProjectDirectories" }}
# * `api/`: API definitions, such as protobuf files and OpenAPI specifications
# * `bin/`: generated project executables.
# * `cmd/`: main CLI Go code
# * `deployments/`: Container publishing configuration
# * `internal/`: internal (non-public) Go packages
# * `scripts/`: internal development shell scripts _(**deprecated**, prefer to use `mise` tasks when appropriate)_
# * `testdata/`: test fixtures and other test data
# * `.vscode/`: VSCode configuration files
# {{- end }}

# {{ stencil.AddToModuleHook "github.com/getgolang/stencil-base" "projectDirectories" (list (stencil.ApplyTemplate "golangProjectDirectories")) }}

# {{- define "golangProjectCommands" }}
# * Build command: `make build`
# * Go code generation command: `make gogenerate`
# * Linter command: `make lint`
# * Formatter command: `make fmt`
# * Unit test command (depends on linter command): `make test`
# {{- end }}

# {{ stencil.AddToModuleHook "github.com/getgolang/stencil-base" "projectCommands" (list (stencil.ApplyTemplate "golangProjectCommands")) }}

# {{- define "golangProjectCodeStyle" }}
# Code linting is validated by the linter command above.

# Go linters are run via `golangci-lint`. Its configuration is defined in `scripts/golangci.yml`.

# Code formatting is enforced by running the formatter command above.
# {{- end }}

# {{ stencil.AddToModuleHook "github.com/getgolang/stencil-base" "projectCodeStyle" (list (stencil.ApplyTemplate "golangProjectCodeStyle")) }}
