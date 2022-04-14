PATH
  remote: .
  specs:
    {{ .appName }}_client (1.63.0)
      grpc (~> 1.38)

GEM
  remote: https://rubygems.org/
  specs:
    google-protobuf (3.19.1)
    googleapis-common-protos-types (1.3.0)
      google-protobuf (~> 3.14)
    grpc (1.42.0)
      google-protobuf (~> 3.18)
      googleapis-common-protos-types (~> 1.0)
    rake (13.0.6)

PLATFORMS
  -darwin-20

DEPENDENCIES
  {{ .appName }}_client!
  rake

BUNDLED WITH
   2.2.29
