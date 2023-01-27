# Remote Buildkit Host on EC2

## Installation

### Packer

- Build the AMI using Packer by running ```packer build``` in the ``images/buildkit/amd64`` folder

### Certificates

Pre-requisites:
- [mkcert](https://github.com/FiloSottile/mkcert) -> make sure to have it installed and available in your PATH


To generate the needed certificates, run ``generate-certificates.sh`` in the `certificates` folder.


This will create the following folders under `/generated`:

- ``/buildkit/client`` - the needed certificates for the GitHub runners to connect to the Buildkit host
- ``/buildkit/host`` - the needed certificates for the Buildkit host to enforce mTLS
- ``/vpn/host`` - the certificate that will be the root/server certificate and stored in ACM for VPN authentication
- ``/vpn/client`` - the certificate that will be used by the GitHub runner to connect to the VPN

You can store those certificates in the secret management tool of your choice.


### Terraform

This project provides 4 Terraform modules:

- ``modules/vpc`` - sets up the VPC and the subnets where the Buildkit hosts will be deployed. Optionally provide your own vpc/subnet ids if you donät want to create a new one
- ``modules/vpn`` - sets up a AWS client VPN endpoint in the provided subnet and configure authentication using the given certificates
- ``modules/buildkit-host`` - creates an EC2 instance with the created buildkit AMI and starts the buildkit daemon with the given certificates
- ``modules/github-config`` - creates the needed GitHub secrets to use the Buildkit host with `docker buildx`

See the root ``main.tf`` for a usage example


### GitHub

See the ``examples/github-workflows.yaml`` workflow for an example job that builds a docker image on the remote buildkit host with the given config