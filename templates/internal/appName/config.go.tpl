{{- $_ := stencil.ApplyTemplate "skipIfNotService" -}}
{{- $_ := file.SetPath (printf "internal/%s/%s" .Config.Name (base file.Path)) }}
// {{ stencil.ApplyTemplate "copyright" }} 

// Description: This file is the focal point of configuration that needs passed
// to various parts of the service.
// Managed: true

package {{ stencil.ApplyTemplate "goPackageSafeName" }} //nolint:revive // Why: We allow [-_].

import (
    "context"
    "os"
    "strings"

    "github.com/getoutreach/gobox/pkg/cfg"
    "github.com/getoutreach/gobox/pkg/log"
    "github.com/getoutreach/gobox/pkg/events"
    "github.com/getoutreach/services/pkg/find"
    ///Block(configImports)
{{ file.Block "configImports" }}
    ///EndBlock(configImports)
)

// Config tracks config needed for {{ .Config.Name }}
type Config struct {
    ListenHost string `yaml:"ListenHost"`
    HTTPPort int `yaml:"HTTPPort"`
    {{- if has "http" (stencil.Arg "serviceActivities") }}
    PublicHTTPPort int `yaml:"PublicHTTPPort"`
    {{- end }}
    {{- if has "grpc" (stencil.Arg "serviceActivities") }}
    GRPCPort int `yaml:"GRPCPort"`
    {{- end }}
    {{- if has "kafka" (stencil.Arg "serviceActivities") }}
    KafkaHosts []string `yaml:"KafkaHosts"`
    KafkaConsumerGroupID string `yaml:"KafkaConsumerGroupID"`
    KafkaConsumerTopic string `yaml:"KafkaConsumerTopic"`
    {{- end }}
    ///Block(config)
{{ file.Block "config"}}
    ///EndBlock(config)
}

// MarshalLog can be used to write config to log
func (c *Config) MarshalLog(addfield func(key string, value interface{})) {
    ///Block(marshalconfig)
{{ file.Block "marshalconfig" }}
	///EndBlock(marshalconfig)
}

// LoadConfig returns a new Config type that has been loaded in accordance to the environment
// that the service was deployed in, with all necessary tweaks made before returning.
// nolint: funlen // Why: This function is long for extensibility reasons since it is generated by bootstrap.
func LoadConfig(ctx context.Context) *Config {
    // NOTE: Defaults should generally be set in the config
    // override jsonnet file: deployments/{{ .Config.Name }}/{{ .Config.Name }}.config.jsonnet
    c := Config{
        // Defaults to [::]/0.0.0.0 which will broadcast to all reachable
        // IPs on a server on the given port for the respective service.
        ListenHost: "",
        HTTPPort: 8000,
	    {{- if has "http" (stencil.Arg "serviceActivities") }}
	    PublicHTTPPort: 8080,
	    {{- end }}
        {{- if has "grpc" (stencil.Arg "serviceActivities") }}
        GRPCPort: 5000,
        {{- end }}
        ///Block(defconfig)
        {{- if file.Block "defconfig" }}
        {{- file.AddDeprecationNotice (printf "Configuration should be declared in deployments/%s/%s.config.jsonnet" .Config.Name .Config.Name) }}
{{ file.Block "defconfig" }}
        {{- end }}
        ///EndBlock(defconfig)
    }

    // Attempt to load a local config file on top of the defaults
	if err := cfg.Load("{{ .Config.Name }}.yaml", &c); os.IsNotExist(err) {
        log.Info(ctx, "No configuration file detected. Using default settings")
    } else if err != nil {
        log.Error(ctx, "Failed to load configuration file, will use default settings", events.NewErrorInfo(err))
    }

    {{- if has "kafka" (stencil.Arg "serviceActivities") }}
	if len(c.KafkaHosts) == 0 {
		brokerDNS, err := find.Service(ctx, find.KafkaPublishBrokers)
		if err != nil {
			log.Fatal(ctx, "missing kafka brokers configuration")
		}

		c.KafkaHosts = []string{brokerDNS + ":9092"}
	}
    {{- end }}

    // Do any necessary tweaks/augmentations to your configuration here
    ///Block(configtweak)
{{ file.Block "configtweak" }}
    ///EndBlock(configtweak)

    log.Info(ctx, "Configuration data of the application:\n", &c)

    return &c
}
