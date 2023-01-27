terraform {
  required_providers {
    github = {
      source = "integrations/github"
      version = "5.16.0"
    }
  }
}

resource "github_actions_secret" "openvpn_config" {
  repository       = var.repository
  secret_name      = "BUILDKIT_OPENVPN_CONFIG"
  plaintext_value  = var.vpn_config
}

resource "github_actions_secret" "private_ip" {
  repository       = var.repository
  secret_name      = "BUILDKIT_HOST_IP"
  plaintext_value  = var.buildkit_host_ip
}

resource "github_actions_secret" "ca_cert" {
  repository       = var.repository
  secret_name      = "BUILDKIT_CLIENT_CA_CERT"
  plaintext_value  = var.buildkit_client_ca_cert
}

resource "github_actions_secret" "cert" {
  repository       = var.repository
  secret_name      = "BUILDKIT_CLIENT_CERT"
  plaintext_value  = var.buildkit_client_cert
}

resource "github_actions_secret" "key" {
  repository       = var.repository
  secret_name      = "BUILDKIT_CLIENT_KEY"
  plaintext_value  = var.buildkit_client_key
}
