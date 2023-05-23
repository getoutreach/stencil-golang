{{- if not (and (stencil.Arg "service") (has "temporal" (stencil.Arg "serviceActivities"))) -}}
  {{- file.Skip "Not a service or does not have temporal in the serviceActivities" -}}
{{- end -}}
resource "datadog_monitor" "temporal_frontend_pod_restarts" {
  type = "query alert"
  name = "{{ .Config.Name | title }} Temporal Frontend Pod Restarts > 3 last 30m"
  query = "max(last_30m):diff(sum:kubernetes_state.container.restarts{kube_container_name:temporal-frontend,kube_namespace:{{ stencil.ApplyTemplate "goPackageSafeName" }}*,!env:development} by {kube_namespace}) > 3"
  tags = local.ddTags
  message = <<EOF
  If we ever have a pod restart, we want to know.
  Note: This monitor will auto-resolve after 30 minutes of no restarts.
  Runbook: "https://github.com/getoutreach/{{ .Config.Name }}/blob/main/documentation/runbooks/pod-restarts.md"
  Notify: ${join(" ", var.P1_notify)}
  EOF
  require_full_window = false
}

resource "datadog_monitor" "temporal_worker_pod_restarts" {
  type = "query alert"
  name = "{{ .Config.Name | title }} Temporal Worker Pod Restarts > 3 last 30m"
  query = "max(last_30m):diff(sum:kubernetes_state.container.restarts{kube_container_name:temporal-worker,kube_namespace:{{ stencil.ApplyTemplate "goPackageSafeName" }}*,!env:development} by {kube_namespace}) > 3"
  tags = local.ddTags
  message = <<EOF
  If we ever have a pod restart, we want to know.
  Note: This monitor will auto-resolve after 30 minutes of no restarts.
  Runbook: "https://github.com/getoutreach/{{ .Config.Name }}/blob/main/documentation/runbooks/pod-restarts.md"
  Notify: ${join(" ", var.P1_notify)}
  EOF
  require_full_window = false
}

resource "datadog_monitor" "temporal_matching_pod_restarts" {
  type = "query alert"
  name = "{{ .Config.Name | title }} Temporal Matching Pod Restarts > 3 last 30m"
  query = "max(last_30m):diff(sum:kubernetes_state.container.restarts{kube_container_name:temporal-matching,kube_namespace:{{ stencil.ApplyTemplate "goPackageSafeName" }}*,!env:development} by {kube_namespace}) > 3"
  tags = local.ddTags
  message = <<EOF
  If we ever have a pod restart, we want to know.
  Note: This monitor will auto-resolve after 30 minutes of no restarts.
  Runbook: "https://github.com/getoutreach/{{ .Config.Name }}/blob/main/documentation/runbooks/pod-restarts.md"
  Notify: ${join(" ", var.P1_notify)}
  EOF
  require_full_window = false
}

resource "datadog_monitor" "temporal_history_pod_restarts" {
  type = "query alert"
  name = "{{ .Config.Name | title }} Temporal History Pod Restarts > 3} last 30m"
  query = "max(last_30m):diff(sum:kubernetes_state.container.restarts{kube_container_name:temporal-history,kube_namespace:{{ stencil.ApplyTemplate "goPackageSafeName" }}*,!env:development} by {kube_namespace}) > 3"
  tags = local.ddTags
  message = <<EOF
  If we ever have a pod restart, we want to know.
  Note: This monitor will auto-resolve after 30 minutes of no restarts.
  Runbook: "https://github.com/getoutreach/{{ .Config.Name }}/blob/main/documentation/runbooks/pod-restarts.md"
  Notify: ${join(" ", var.P1_notify)}
  EOF
  require_full_window = false
}

// <<Stencil::Block(tfCustomTemporalDatadog)>>
{{ file.Block "tfCustomTemporalDatadog" }}
// <</Stencil::Block>>
