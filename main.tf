terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~> 4.0"
    }
    github = {
      source = "integrations/github"
      version = "5.16.0"
    }
  }
}

provider "aws" {
  region = "eu-central-1"
}

provider "github" {
  token = var.github_pat
}

module "vpc" {
  source = "./modules/vpc"
  subnet_availability_zone = "eu-central-1a"
}

module "vpn" {
  source = "./modules/vpn"

  cert_chain = file("${path.root}/certificates/generated/vpn/ca.crt")
  server_cert = file("${path.root}/certificates/generated/vpn/host/cert.crt")
  server_key = file("${path.root}/certificates/generated/vpn/host/key.key")

  client_tls_cert = file("${path.root}/certificates/generated/vpn/client/cert.pem")
  client_tls_key = file("${path.root}/certificates/generated/vpn/client/key.key")

  buildkit_subnet_id = module.vpc.subnet_id
  buildkit_security_group_id = module.vpc.security_group_id
  buildkit_vpc_cidr_block = module.vpc.cidr_block
  buildkit_vpc_id = module.vpc.vpc_id

  depends_on = [module.vpc]
}

module "buildkit-host-001" {
  source = "./modules/buildkit-host"
  host_name = "buildkit-host-001"
  ec2_instance_type = "t3.micro"

  tls_ca_cert = file("${path.root}/certificates/generated/buildkit/host/ca.pem")
  tls_cert = file("${path.root}/certificates/generated/buildkit/host/cert.pem")
  tls_key = file("${path.root}/certificates/generated/buildkit/host/key.pem")

  subnet_id = module.vpc.subnet_id
  vpc_security_group_ids = [module.vpc.security_group_id]

  depends_on = [module.vpc]
}

module "github-config" {
  source = "./modules/github-config"

  repository = "payment-gateway"
  vpn_config = module.vpn.openvpn_config
  buildkit_host_ip = module.buildkit-host-001.private_ip
  buildkit_client_ca_cert = file("${path.root}/certificates/generated/buildkit/client/ca.pem")
  buildkit_client_cert = file("${path.root}/certificates/generated/buildkit/client/cert.pem")
  buildkit_client_key = file("${path.root}/certificates/generated/buildkit/client/key.pem")
}