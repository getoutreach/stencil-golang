{{- $_ := stencil.ApplyTemplate "skipIfNotService" -}}
# Fill these in with DataDog users/integrations to notify
// <<Stencil::Block(tfNotificationPriorities)>>
{{- if file.Block "tfNotificationPriorities" }}
{{ file.Block "tfNotificationPriorities" }}
{{- else }}
P1_notify = []
P2_notify = []
{{- end }}
// <</Stencil::Block>>

# Fill these in with tags for your datadog dashboards/monitors
# Team and service names will be added automatically elsewhere, add anything additional to those two in here
// <<Stencil::Block(tfAdditionalDdTags)>>
{{- if file.Block "tfAdditionalDdTags" }}
{{ file.Block "tfAdditionalDdTags" }}
{{- else }}
additional_dd_tags = []
{{- end }}
// <</Stencil::Block>>

# Replace the following values with adequate yellow/red
# thresholds for your service call latencies
#
# Note that threshold affect presentation of Performance charts
# and not used for monitors/alerts
// <<Stencil::Block(tfLatencyThresholdsMs)>>
{{- if file.Block "tfLatencyThresholdsMs" }}
{{ file.Block "tfLatencyThresholdsMs" }}
{{- else }}
Latency_red_line_ms    = 500
Latency_yellow_line_ms = 200
{{- end }}
// <</Stencil::Block>>

# Replace the following values with adequate yellow/red
# thresholds (in percentage) for your service call latencies
#
# Note that threshold affect presentation of QoS charts
# and not used for monitors/alerts
// <<Stencil::Block(tfLatencyThresholdsPercentage)>>
{{- if file.Block "tfLatencyThresholdsPercentage" }}
{{ file.Block "tfLatencyThresholdsPercentage" }}
{{- else }}
Qos_red_line    = 98
Qos_yellow_line = 99
{{- end }}
// <</Stencil::Block>>

// <<Stencil::Block(tfCustomVars)>>
{{ file.Block "tfCustomVars" }}
// <</Stencil::Block>>
