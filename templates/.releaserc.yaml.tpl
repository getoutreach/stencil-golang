{{- file.Skip "Virtual file for .releaserc.yaml.tpl module hooks" }}

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
