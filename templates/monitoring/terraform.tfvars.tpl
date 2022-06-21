# Fill these in with DataDog users/integrations to notify
///Block(tfNotificationPriorities)
{{- if file.Block "tfNotificationPriorities" }}
{{ file.Block "tfNotificationPriorities" }}
{{- else }}
P1_notify = []
P2_notify = []
{{- end }}
///EndBlock(tfNotificationPriorities)

# Fill these in with tags for your datadog dashboards/monitors
# Team and service names will be added automatically elsewhere, add anything additional to those two in here
///Block(tfAdditionalDdTags)
{{- if file.Block "tfAdditionalDdTags" }}
{{ file.Block "tfAdditionalDdTags" }}
{{- else }}
additional_dd_tags = []
{{- end }}
///EndBlock(tfAdditionalDdTags)

# Replace the following values with adequate yellow/red
# thresholds for your service call latencies
#
# Note that threshold affect presentation of Performance charts
# and not used for monitors/alerts
///Block(tfLatencyThresholdsMs)
{{- if file.Block "tfLatencyThresholdsMs" }}
{{ file.Block "tfLatencyThresholdsMs" }}
{{- else }}
Latency_red_line_ms    = 500
Latency_yellow_line_ms = 200
{{- end }}
///EndBlock(tfLatencyThresholdsMs)

# Replace the following values with adequate yellow/red
# thresholds (in percentage) for your service call latencies
#
# Note that threshold affect presentation of QoS charts
# and not used for monitors/alerts
///Block(tfLatencyThresholdsPercentage)
{{- if file.Block "tfLatencyThresholdsPercentage" }}
{{ file.Block "tfLatencyThresholdsPercentage" }}
{{- else }}
Qos_red_line    = 98
Qos_yellow_line = 99
{{- end }}
///EndBlock(tfLatencyThresholdsPercentage)

///Block(tfCustomVars)
{{ file.Block "tfCustomVars" }}
///EndBlock(tfCustomVars)
