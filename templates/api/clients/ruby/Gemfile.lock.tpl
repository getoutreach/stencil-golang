{{- $_ := stencil.ApplyTemplate "skipGrpcClient" "ruby" -}}
PATH
  remote: .
  specs:
    {{ .Config.Name }}_client (1.0.0)
      grpc (~> 1.72)

GEM
  remote: https://rubygems.org/
  specs:
    google-protobuf (3.25.5)
    googleapis-common-protos-types (1.5.0)
      google-protobuf (~> 3.14)
    grpc (1.72.0)
      google-protobuf (>= 3.25, < 5.0)
      googleapis-common-protos-types (~> 1.0)
    rake (13.2.1)

PLATFORMS
  -darwin-20

DEPENDENCIES
  {{ .Config.Name }}_client!
  rake

BUNDLED WITH
   2.3.26
