# yaml-language-server: $schema=https://json.schemastore.org/golangci-lint
lintroller:
  tier: "{{ stencil.Arg "lintroller" }}"

# Linter settings
linters-settings:
  errcheck:
    check-blank: true
  govet:
    check-shadowing: true
  revive:
    rules:
      # Enable the default golint rules. We must include these because
      # we configure a single rule, which disables the default rules.
      - name: blank-imports
      - name: context-as-argument
      - name: context-keys-type
      - name: dot-imports
      - name: error-return
      - name: error-strings
      - name: error-naming
      - name: exported
      - name: increment-decrement
      - name: var-naming
      - name: var-declaration
      - name: package-comments
      - name: range
      - name: receiver-naming
      - name: time-naming
      - name: unexported-return
      - name: indent-error-flow
      - name: errorf
      - name: empty-block
      - name: superfluous-else
      - name: unreachable-code
      - name: redefines-builtin-id
      # While we agree with this rule, right now it would break too many
      # projects. So, we disable it by default.
      - name: unused-parameter
        disabled: true
  gocyclo:
    min-complexity: 25
  dupl:
    threshold: 100
  goconst:
    min-len: 3
    min-occurrences: 3
  lll:
    line-length: 140
  gocritic:
    enabled-tags:
      - diagnostic
      - experimental
      - opinionated
      - performance
      - style
    disabled-checks:
      - whyNoLint # Doesn't seem to work properly
      # Suggests bad simplifications (After is not identical to !Before).
      # TODO(jkinkead): Remove when we have a version of go-critic with
      # https://github.com/go-critic/go-critic/pull/1281 merged.
      - timeCmpSimplify
  funlen:
    lines: 500
    statements: 50

linters:
  # Inverted configuration with enable-all and disable is not scalable during updates of golangci-lint.
  disable-all: true
  enable:
    - bodyclose
    - dogsled
    - errcheck
    - errorlint
    - exhaustive # Checks exhaustiveness of enum switch statements.
    - exportloopref # Checks for pointers to enclosing loop variables.
    - funlen
    - gochecknoinits
    - goconst
    - gocritic
    - gocyclo
    - gofmt
    - goimports
    - revive
    - gosec
    - gosimple
    - govet
    - ineffassign
    - lll
    # - misspell        # The reason we're disabling this right now is because it uses 1/2 of the memory of the run.
    - nakedret
    - staticcheck
    - typecheck
    - unconvert
    - unparam
    - unused
    - whitespace

issues:
  exclude:
    # We allow error shadowing
    - 'declaration of "err" shadows declaration at'

  # Excluding configuration per-path, per-linter, per-text and per-source
  exclude-rules:
    # Exclude some linters from running on tests files.
    - path: _test\.go
      linters:
        - gocyclo
        - errcheck
        - gosec
        - funlen
        - gochecknoglobals # Globals in test files are tolerated.
        - goconst # Repeated consts in test files are tolerated.
    # This rule is buggy and breaks on our `///Block` lines.  Disable for now.
    - linters:
        - gocritic
      text: "commentFormatting: put a space"
    # This rule incorrectly flags nil references after assert.Assert(t, x != nil)
    - path: _test\.go
      text: "SA5011"
      linters:
        - staticcheck
    - linters:
        - lll
      source: "^//go:generate "
{{- $hook := (stencil.GetModuleHook "golangci-lint/exclude-rules") }}
{{- if $hook }}
{{ toYaml $hook | indent 4 }}
{{- end }}

output:
  format: colored-line-number
  sort-results: true
  print-severity: true
