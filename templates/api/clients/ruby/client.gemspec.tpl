{{- $_ := stencil.ApplyTemplate "skipGrpcClient" "ruby" -}}
require_relative 'lib/{{ .Config.Name }}_client/version'

Gem::Specification.new do |spec|
  spec.name          = "{{ .Config.Name }}_client"
  spec.version       = {{ title .Config.Name }}Client::VERSION
  spec.summary       = "ruby client for {{ .Config.Name }} service"
  spec.authors       = ["{{ stencil.Arg "reportingTeam" }}"]
  spec.homepage      = "https://github.com/getoutreach/{{ .Config.Name }}"
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["github_repo"] = "ssh://github.com/getoutreach/{{ .Config.Name }}"

  spec.required_ruby_version = Gem::Requirement.new(">= 2.6.6")
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.require_paths = ["lib", "lib/{{ .Config.Name }}_client"]
  spec.add_dependency 'grpc', '~> 1.38'
  spec.add_development_dependency 'rake'
end
