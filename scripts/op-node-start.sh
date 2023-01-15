#!/bin/sh
set -eou

# Install curl if not already installed
if ! command -v curl &> /dev/null; then
  echo "Installing curl..."
  apk add curl
fi

# Wait for geth to be ready
echo "Waiting for op-geth..."
curl \
  -X POST \
  --silent \
  --output /dev/null \
  --retry-connrefused \
  --retry 1000 \
  --retry-delay 1 \
  -d '{"jsonrpc":"2.0","id":0,"method":"eth_chainId","params":[]}' \
  http://op-geth:8545

op-node --help

# Run op-node
exec op-node \
  --l1=$OP_NODE__RPC_ENDPOINT \
  --l2=http://op-geth:8551 \
  --network=$NETWORK_NAME \
  --rpc.addr=127.0.0.1 \
  --rpc.port=9545 \
  --l2.jwt-secret=/jwt/jwt.txt \
  --l1.trustrpc \
  --l1.rpckind=$OP_NODE__RPC_TYPE \
  --metrics.enabled \
  --metrics.addr=0.0.0.0 \
  --metrics.port=7300 \
  $@
