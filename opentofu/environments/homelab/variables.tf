variable "authentik_url" {
  description = "Base URL for the Authentik instance."
  type        = string
}

variable "authentik_token" {
  description = "API token for the Authentik provider."
  type        = string
  sensitive   = true
}
