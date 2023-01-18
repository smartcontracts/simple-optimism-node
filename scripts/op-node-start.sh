#!/bin/sh
set -eou

source ./utils.sh

install "curl"

echo "Waiting for op-geth..."
chainwait "http://op-geth:8545"

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
