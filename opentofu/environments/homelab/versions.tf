terraform {
  required_version = ">= 1.10.0"

  required_providers {
    authentik = {
      source  = "goauthentik/authentik"
      version = "~> 2025.10"
    }
  }
}
