locals {
  vpn_endpoint = replace(aws_ec2_client_vpn_endpoint.buildkit.dns_name, "*", "random-string")
  ovpn_config = templatefile("${path.module}/templates/configuration.ovpn", {
    vpn_endpoint = local.vpn_endpoint
    ca = var.cert_chain
    cert = var.client_tls_cert
    cert_key = var.client_tls_key
  })
}

resource "aws_acm_certificate" "server" {
  private_key = var.server_key
  certificate_body = var.server_cert
  certificate_chain = var.cert_chain

  tags = {
    Name      = "buildkit-vpn-server-certificate"
    ManagedBy = "terraform"
  }
}

resource "aws_ec2_client_vpn_endpoint" "buildkit" {
  description            = "buildkit-vpn"
  server_certificate_arn = aws_acm_certificate.server.arn
  client_cidr_block      = "172.31.16.0/20"

  security_group_ids        = [var.buildkit_security_group_id]
  vpc_id = var.buildkit_vpc_id
  authentication_options {
    type                       = "certificate-authentication"
    root_certificate_chain_arn = aws_acm_certificate.server.arn
  }

  connection_log_options {
    enabled               = false
  }

  tags = {
    Name      = "buildkit-vpn-endpoint"
    ManagedBy = "terraform"
  }
}

resource "aws_ec2_client_vpn_network_association" "buildkit" {
  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.buildkit.id
  subnet_id              = var.buildkit_subnet_id
}

resource "aws_ec2_client_vpn_route" "internet" {
  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.buildkit.id
  destination_cidr_block = "0.0.0.0/0"
  target_vpc_subnet_id   = aws_ec2_client_vpn_network_association.buildkit.subnet_id
}

resource "aws_ec2_client_vpn_authorization_rule" "internet" {
  description = "Allow access to the internet"
  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.buildkit.id
  target_network_cidr    = "0.0.0.0/0"
  authorize_all_groups   = true
}

resource "aws_ec2_client_vpn_authorization_rule" "internal" {
  description = "Allow access to Buildkit VPC"
  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.buildkit.id
  target_network_cidr    = var.buildkit_vpc_cidr_block
  authorize_all_groups   = true
}

resource "local_file" "local" {
  filename = "./vpn-configuration.ovpn"
  content = templatefile("${path.module}/templates/configuration.ovpn", {
    vpn_endpoint = local.vpn_endpoint
    ca = var.cert_chain
    cert = var.client_tls_cert
    cert_key = var.client_tls_key
  })
}
