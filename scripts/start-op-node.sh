#!/bin/sh
set -e

if [ -n "${IS_CUSTOM_CHAIN}" ]; then
  export EXTENDED_ARG="${EXTENDED_ARG:-} --rollup.config=/chainconfig/rollup.json"
else
  export EXTENDED_ARG="${EXTENDED_ARG:-} --network=$NETWORK_NAME --rollup.load-protocol-versions=true --rollup.halt=major"
fi

# Start op-node.
exec op-node \
  --l1=$OP_NODE__RPC_ENDPOINT \
  --l2="http://op-${COMPOSE_PROFILES}:8551" \
  --l2.enginekind=$COMPOSE_PROFILES \
  --rpc.addr=0.0.0.0 \
  --rpc.port=9545 \
  --l2.jwt-secret=/shared/jwt.txt \
  --l1.trustrpc \
  --l1.rpckind=$OP_NODE__RPC_TYPE \
  --l1.beacon=$OP_NODE__L1_BEACON \
  --metrics.enabled \
  --metrics.addr=0.0.0.0 \
  --metrics.port=7300 \
  --syncmode=execution-layer \
  $EXTENDED_ARG $@
