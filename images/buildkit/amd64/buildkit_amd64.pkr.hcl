packer {
  required_plugins {
    amazon = {
      version = ">= 1.1.1"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

source "amazon-ebs" "buildkit" {
  ami_name      = "buildkit-amzn2-amd64-${formatdate("YYYYMMDDhhmm", timestamp())}"
  instance_type = "t2.micro"
  region        = "eu-central-1"

  source_ami_filter {
    filters = {
      name                = "amzn2-ami-kernel-5.*-hvm-*-x86_64-gp2"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    most_recent = true
    owners      = ["137112412989"]
  }
  ssh_username = "ec2-user"

  launch_block_device_mappings {
    device_name           = "/dev/xvda"
    volume_size           = "8"
    volume_type           = "gp3"
  }
}

build {
  name = "buildkit"
  sources = [
    "source.amazon-ebs.buildkit"
  ]

  provisioner "file" {
    content = file("install_buildkit.sh")
    destination = "/tmp/install_buildkit.sh"
  }

  provisioner "shell" {
    environment_vars = []
    inline = [
      "sudo chmod +x /tmp/install_buildkit.sh",
      "sudo /tmp/install_buildkit.sh"
    ]
  }
}
