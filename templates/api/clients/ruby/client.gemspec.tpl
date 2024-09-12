{{- $_ := stencil.ApplyTemplate "skipGrpcClient" "ruby" -}}
require_relative 'lib/{{ .Config.Name }}_client/version'

Gem::Specification.new do |spec|
  spec.name          = "{{ .Config.Name }}_client"
  spec.version       = {{ title .Config.Name }}Client::VERSION
  {{- if stencil.Arg "service" }}
  spec.summary       = "gRPC client for {{ .Config.Name }} service"
  {{- else }}
  spec.summary       = "gRPC types for {{ .Config.Name }}"
  {{- end }}
  spec.authors       = ["{{ stencil.Arg "reportingTeam" }}"]
  spec.homepage      = "https://github.com/getoutreach/{{ .Config.Name }}"
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["github_repo"] = "ssh://github.com/getoutreach/{{ .Config.Name }}"

  spec.required_ruby_version = Gem::Requirement.new(">= {{ stencil.Arg "versions.grpcClients.ruby" }}")
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.require_paths = ["lib", "lib/{{ .Config.Name }}_client"]
  spec.add_dependency 'grpc', '~> 1.38'
  spec.add_development_dependency 'rake'
  ## <<Stencil::Block(extraGemSpec)>>
{{ file.Block "extraGemSpec" }}
  ## <</Stencil::Block>>
end
