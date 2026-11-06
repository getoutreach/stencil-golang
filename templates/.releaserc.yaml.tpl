{{- file.Skip "Virtual file for .releaserc.yaml.tpl module hooks" }}

{{- define "commands-binary-build" }}
  # Build the binaries
  - - "@semantic-release/exec"
    # We use generateNotesCmd instead of a different step because it has access
    # to last/nextRelease due to when the step runs.
    - generateNotesCmd: "make release APP_VERSION=${nextRelease.version}"
{{- end }}

{{- define "commands-gh-release" }}
  # Create the GitHub Release
  - - "@semantic-release/github"
    - assets:
        - "dist/*.tar.gz"
        - "dist/checksums.txt"
{{- end }}

{{- if or (and (stencil.Arg "commands") (stencil.Arg "releaseOptions.enableCLIs")) (stencil.Arg "releaseOptions.force") }}
  {{ stencil.AddToModuleHook "github.com/getoutreach/stencil-base" "buildBinaryReleaseConfig" (list (stencil.ApplyTemplate "commands-binary-build")) }}
  {{ stencil.AddToModuleHook "github.com/getoutreach/stencil-base" "GHReleaseConfig" (list (stencil.ApplyTemplate "commands-gh-release")) }}
{{- end}}

{{- define "grpcClients-pre-release-config" }}
{{- if or (not (stencil.Arg "service")) (has "grpc" (stencil.Arg "serviceActivities")) }}
  {{- if has "node" (stencil.Arg "grpcClients") }}
  # Bump npm package.json version, and release to npm/github packages.
  # See devbase for the Github Packages part.
  - - "@semantic-release/npm"
    - pkgRoot: api/clients/node
  {{- end -}}
  {{- if has "ruby" (stencil.Arg "grpcClients") }}
  # Release Ruby packages
  - - "@semantic-release/exec"
    # We use generateNotesCmd because prepareCmd is not ran on dry-run
    - generateNotesCmd: |-
        ./scripts/shell-wrapper.sh ruby/build.sh ${nextRelease.version} 1>&2
      publishCmd: |-
        DRYRUN=${options.dryrun} ./scripts/shell-wrapper.sh ruby/publish.sh ${nextRelease.version}
  {{- end }}
  {{- if not (empty (stencil.Arg "grpcClients")) }}
  # Store the manifest version updates in git
  - - "@semantic-release/git"
    - assets:
        {{- if has "node" (stencil.Arg "grpcClients") }}
        - api/clients/node/package.json
        {{- end }}
        {{- if has "ruby" (stencil.Arg "grpcClients") }}
        - api/clients/ruby/lib/{{ .Config.Name }}_client/version.rb
        {{- end }}
  {{- end }}
{{- end }}
{{- end }}

{{ stencil.AddToModuleHook "github.com/getoutreach/stencil-base" "preGHReleaseConfig" (list (stencil.ApplyTemplate "grpcClients-pre-release-config")) }}
