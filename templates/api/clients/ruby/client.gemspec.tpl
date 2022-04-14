require_relative 'lib/{{ .appName }}_client/version'

Gem::Specification.new do |spec|
  spec.name          = "{{ .appName }}_client"
  spec.version       = {{ .titleName }}Client::VERSION
  spec.summary       = "ruby client for {{ .appName }} service"
  spec.authors       = ["{{ .manifest.ReportingTeam }} "]
  spec.homepage      = "https://github.com/getoutreach/{{ .appName }}"
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["github_repo"] = "ssh://github.com/getoutreach/{{ .appName }}"

  spec.required_ruby_version = Gem::Requirement.new(">= {{ .versions.ruby }}")
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.require_paths = ["lib", "lib/{{ .appName }}_client"]
  spec.add_dependency 'grpc', '~> 1.38'
  spec.add_development_dependency 'rake'
end
