{{- $_ := stencil.ApplyTemplate "skipGrpcClient" "ruby" -}}
{{ file.Static }}
PATH
  remote: .
  specs:
    {{ .Config.Name }}_client (0.0.0)
      grpc (~> 1.59)

GEM
  remote: https://rubygems.org/
  specs:
    google-protobuf (3.25.0)
    google-protobuf (3.25.0-arm64-darwin)
    googleapis-common-protos-types (1.10.0)
      google-protobuf (~> 3.18)
    grpc (1.59.2)
      google-protobuf (~> 3.24)
      googleapis-common-protos-types (~> 1.0)
    rake (13.1.0)
PLATFORMS
  -darwin-20
  arm64-darwin-22

DEPENDENCIES
  {{ .Config.Name }}_client!
  rake

BUNDLED WITH
   2.3.26
