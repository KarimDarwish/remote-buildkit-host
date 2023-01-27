#!/bin/bash

tmp_dir="tmp"
cert_dir="generated"
easy_rsa_file_name="easy-rsa.tar.gz"

# --------------------------------
#       VPN Certificates
# --------------------------------

echo "--------------------------------"
echo "        VPN Certificates        "
echo "--------------------------------"

mkdir -p $tmp_dir

echo "Downloading easy-rsa to generate certificates for VPN authentication..."
curl -s -o ./$tmp_dir/$easy_rsa_file_name -L https://github.com/OpenVPN/easy-rsa/releases/download/v3.1.2/EasyRSA-3.1.2.tgz

tar -xf ./$tmp_dir/$easy_rsa_file_name -C $tmp_dir

echo "Downloaded easy-rsa"

echo "Initializing PKI..."
export EASYRSA_BATCH=1

(cd $tmp_dir && ./EasyRSA-3.1.2/easyrsa init-pki)
(cd $tmp_dir && ./EasyRSA-3.1.2/easyrsa build-ca nopass)
(cd $tmp_dir && ./EasyRSA-3.1.2/easyrsa build-server-full server nopass)
(cd $tmp_dir && ./EasyRSA-3.1.2/easyrsa build-client-full vpn-client.buildkit.tld nopass)

mkdir -p generated/vpn
mkdir -p generated/vpn/host
mkdir -p generated/vpn/client

cp ./$tmp_dir/pki/private/ca.key ./generated/vpn/ca.key
cp ./$tmp_dir/pki/ca.crt ./generated/vpn/ca.crt

# Host Certificates
cp ./$tmp_dir/pki/ca.crt ./generated/vpn/host/ca.crt
cp ./$tmp_dir/pki/issued/server.crt ./generated/vpn/host/cert.crt
cp ./$tmp_dir/pki/private/server.key ./generated/vpn/host/key.key

# Client Certificates

cp ./$tmp_dir/pki/ca.crt ./generated/vpn/client/ca.crt
cp ./$tmp_dir/pki/issued/vpn-client.buildkit.tld.crt ./generated/vpn/client/cert.crt
cp ./$tmp_dir/pki/private/vpn-client.buildkit.tld.key ./generated/vpn/client/key.key

openssl x509 -in ./generated/vpn/client/cert.crt -out ./generated/vpn/client/cert.pem -outform PEM
rm ./generated/vpn/client/cert.crt

echo "Created VPN Certificates"


# --------------------------------
#      Buildkit Certificates
# --------------------------------
echo "--------------------------------"
echo "     Buildkit Certificates      "
echo "--------------------------------"

default_san="127.0.0.1"
san_client=client


if ! command -v mkcert >/dev/null; then
	echo "Missing mkcert (https://github.com/FiloSottile/mkcert)"
	exit 1
fi

mkdir -p generated/buildkit
mkdir -p generated/buildkit/host
mkdir -p generated/buildkit/client

echo "Running mkcert to generate certificates..."

CAROOT=$(pwd) mkcert -cert-file generated/buildkit/host/cert.pem -key-file generated/buildkit/host/key.pem $default_san >/dev/null 2>&1
CAROOT=$(pwd) mkcert -client -cert-file generated/buildkit/client/cert.pem -key-file generated/buildkit/client/key.pem ${san_client} >/dev/null 2>&1
chmod 777 rootCA.pem
chmod 777 rootCA-key.pem
chmod 777 generated/buildkit/host
chmod 777 generated/buildkit/client

cp -f rootCA.pem generated/buildkit/host/ca.pem
cp -f rootCA.pem generated/buildkit/client/ca.pem
cp -f rootCA.pem generated/buildkit/ca.pem
cp -f rootCA-key.pem generated/buildkit/ca.key

echo "Certificates created under /generated/buildkit"


rm rootCA.pem
rm rootCA-key.pem
rm -r $tmp_dir