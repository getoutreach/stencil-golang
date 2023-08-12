{{- $_ := stencil.ApplyTemplate "skipIfNotService" -}}
# Navigate to https://outreach.app.cx138.coralogix.com/#/webhooks, click on
# your PD webhook, the URL will update and indicate the ID to use when setting
# these variables
variable "CoralogixPD_P1_notify" {
  type    = number
  default = 0
}
variable "CoralogixPD_P2_notify" {
  type    = number
  default = 0
}
