terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~> 4.0"
    }
    http = {
      source = "hashicorp/http"
      version = "3.2.1"
    }
  }
}

provider "aws" {
  region = "eu-central-1"
}

module "vpc" {
  source = "./modules/vpc"
  subnet_availability_zone = "eu-central-1a"
}

module "vpn" {
  source = "./modules/vpn"

  cert_chain = file("${path.root}/.certs/ca.crt")
  server_cert = file("${path.root}/.certs/issued/server.crt")
  server_key = file("${path.root}/.certs/private/server.key")

  buildkit_subnet_id = module.vpc.subnet_id
  buildkit_security_group_id = module.vpc.security_group_id
  buildkit_vpc_cidr_block = "10.0.0.0/16"
  buildkit_vpc_id = module.vpc.vpc_id
}

module "buildkit-host-001" {
  source = "./modules/buildkit-host"
  host_name = "buildkit-host-001"
  ec2_instance_type = "t3.micro"

  tls_ca_cert = file("${path.root}/.certs/ca.crt")
  tls_cert = file("${path.root}/.certs/issued/server.crt")
  tls_key = file("${path.root}/.certs/private/server.key")

  subnet_id = module.vpc.subnet_id
  vpc_security_group_ids = [module.vpc.security_group_id]

  depends_on = [module.vpc]
}