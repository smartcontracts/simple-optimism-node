#!/bin/sh
set -e

# Retrieve kzg commitment files, links for points files sourced from:
# https://github.com/Layr-Labs/eigenda-operator-setup/blob/51857209ab9c49ca8b639d1e9a977d5bff48ecda/srs_setup.sh
if [ ! -e /data/verified ]; then
  wget https://srs-mainnet.s3.amazonaws.com/kzg/g1.point --output-document=/data/g1.point
  wget https://srs-mainnet.s3.amazonaws.com/kzg/g2.point.powerOf2 --output-document=/data/g2.point.powerOf2
  wget https://raw.githubusercontent.com/Layr-Labs/eigenda-operator-setup/master/resources/srssha256sums.txt --output-document=/data/srssha256sums.txt
  if (cd data && sha256sum -c srssha256sums.txt); then
    echo "Checksums match. Verification successful."
    touch /data/verified
  else
    echo "Error: Checksums do not match. Please delete this folder and try again."
    exit 1
  fi
fi

exec eigenda-proxy \
  --addr=0.0.0.0 \
  --port=4242 \
  --eigenda-disperser-rpc=disperser-holesky.eigenda.xyz:443 \
  --eigenda-eth-rpc=$OP_NODE__RPC_ENDPOINT \
  --eigenda-signer-private-key-hex=$(head -c 32 /dev/urandom | xxd -p -c 32) \
  --eigenda-svc-manager-addr=0xD4A7E1Bd8015057293f0D0A557088c286942e84b \
  --eigenda-status-query-timeout=45m \
  --eigenda-g1-path=/data/g1.point \
  --eigenda-g2-tau-path=/data/g2.point.powerOf2 \
  --eigenda-disable-tls=false \
  --eigenda-eth-confirmation-depth=1 \
  --eigenda-max-blob-length=300MiB
