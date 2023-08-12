{{- $_ := stencil.ApplyTemplate "skipIfNotService" -}}
terraform {
  # This is a top-level project, so we pin to specific versions.  All child
  # modules should use versions ">=" version specifiers for maximum flexibility.
  required_providers {
    datadog = {
      source  = "datadog/datadog"
      version = ">= 3.0.0, < 4.0.0"
    }
    vault = {
      source = "hashicorp/vault"
      version = ">= 2.15.0"
    }
    coralogix = {
      version = ">= 1.6.6"
      source  = "coralogix/coralogix"
    }
  }
  required_version = ">= 0.13"
}
