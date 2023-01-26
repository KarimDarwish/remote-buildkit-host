variable "subnet_id" {
  type = string
}

variable "vpc_security_group_ids" {
  type = list(string)
}
variable "ec2_instance_type" {
  type    = string
  default = "t3.micro"
}

variable "host_name" {
  type = string
}

variable "tls_ca_cert" {
  type = string
}

variable "tls_cert" {
  type = string
}

variable "tls_key" {
  type = string
}

variable "root_block_device" {
  type = object({
    volume_size           = string,
    volume_type           = string,
    encrypted             = bool,
    delete_on_termination = bool
  })

  default = {
    volume_size           = 8
    volume_type           = "gp3"
    encrypted             = true
    delete_on_termination = false
  }
}