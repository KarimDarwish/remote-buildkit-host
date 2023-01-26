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
  source = "modules/vpc"
  subnet_availability_zone = "eu-central-1a"
}

module "buildkit-host-001" {
  source = "./modules/buildkit-host"
  host_name = "buildkit-host-001"
  ec2_instance_type = "t3.micro"

  tls_ca_cert = file("${path.root}/.certs/daemon/ca.pem")
  tls_cert = file("${path.root}/.certs/daemon/cert.pem")
  tls_key = file("${path.root}/.certs/daemon/key.pem")

  subnet_id = "module.vpc.subnet_id"
  vpc_security_group_ids = ["module.vpc.security_group_id"]

  depends_on = [module.vpc]
}