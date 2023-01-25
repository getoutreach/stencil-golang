{{- if not (and (stencil.Arg "service") (has "temporal" (stencil.Arg "serviceActivities"))) -}}
  {{- file.Skip "Not a service" -}}
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

resource "datadog_monitor" "temporal_frontend_available_pods_low" {
  type = "query alert"
  name = "{{ .Config.Name | title }} Available Temporal frontend Pods Low"
  query = "max(last_10m):avg:kubernetes_state.deployment.replicas_available{deployment:temporal-frontend,kube_namespace:{{ stencil.ApplyTemplate "goPackageSafeName" }}*,env:production} by {kube_namespace} < ${var.available_pods_low_count}"
  tags = local.ddTags
  message = <<EOF
  The {{ .Config.Name | title }} temporal frontend replica count should be at least ${var.available_pods_low_count}, which is also the PDB. If it's lower, that's below the PodDisruptionBudget and we're likely headed toward a total outage of {{ .Config.Name | title }}.
  Note: This P1 alert only includes production
  Runbook: "https://github.com/getoutreach/{{ .Config.Name }}/blob/main/documentation/runbooks/available-pods-low.md"
  Notify: ${join(" ", var.P1_notify)}
  EOF
}

resource "datadog_monitor" "temporal_history_available_pods_low" {
  type = "query alert"
  name = "{{ .Config.Name | title }} Available Temporal history Pods Low"
  query = "max(last_10m):avg:kubernetes_state.deployment.replicas_available{deployment:temporal-history,kube_namespace:{{ stencil.ApplyTemplate "goPackageSafeName" }}*,env:production} by {kube_namespace} < ${var.available_pods_low_count}"
  tags = local.ddTags
  message = <<EOF
  The {{ .Config.Name | title }} temporal history replica count should be at least ${var.available_pods_low_count}, which is also the PDB. If it's lower, that's below the PodDisruptionBudget and we're likely headed toward a total outage of {{ .Config.Name | title }}.
  Note: This P1 alert only includes production
  Runbook: "https://github.com/getoutreach/{{ .Config.Name }}/blob/main/documentation/runbooks/available-pods-low.md"
  Notify: ${join(" ", var.P1_notify)}
  EOF
}

resource "datadog_monitor" "temporal_matching_available_pods_low" {
  type = "query alert"
  name = "{{ .Config.Name | title }} Available Temporal matching Pods Low"
  query = "max(last_10m):avg:kubernetes_state.deployment.replicas_available{deployment:temporal-matching,kube_namespace:{{ stencil.ApplyTemplate "goPackageSafeName" }}*,env:production} by {kube_namespace} < ${var.available_pods_low_count}"
  tags = local.ddTags
  message = <<EOF
  The {{ .Config.Name | title }} temporal matching replica count should be at least ${var.available_pods_low_count}, which is also the PDB. If it's lower, that's below the PodDisruptionBudget and we're likely headed toward a total outage of {{ .Config.Name | title }}.
  Note: This P1 alert only includes production
  Runbook: "https://github.com/getoutreach/{{ .Config.Name }}/blob/main/documentation/runbooks/available-pods-low.md"
  Notify: ${join(" ", var.P1_notify)}
  EOF
}

resource "datadog_monitor" "temporal_worker_available_pods_low" {
  type = "query alert"
  name = "{{ .Config.Name | title }} Available Temporal worker Pods Low"
  query = "max(last_10m):avg:kubernetes_state.deployment.replicas_available{deployment:temporal-worker,kube_namespace:{{ stencil.ApplyTemplate "goPackageSafeName" }}*,env:production} by {kube_namespace} < ${var.available_pods_low_count}"
  tags = local.ddTags
  message = <<EOF
  The {{ .Config.Name | title }} temporal worker replica count should be at least ${var.available_pods_low_count}, which is also the PDB. If it's lower, that's below the PodDisruptionBudget and we're likely headed toward a total outage of {{ .Config.Name | title }}.
  Note: This P1 alert only includes production
  Runbook: "https://github.com/getoutreach/{{ .Config.Name }}/blob/main/documentation/runbooks/available-pods-low.md"
  Notify: ${join(" ", var.P1_notify)}
  EOF
}

// <<Stencil::Block(tfCustomTemporalDatadog)>>
{{ file.Block "tfCustomTemporalDatadog" }}
// <</Stencil::Block>>
