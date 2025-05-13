#!/bin/sh
set -e

if [ -n "${IS_CUSTOM_CHAIN}" ]; then
  export EXTENDED_ARG="${EXTENDED_ARG:-} --rollup.config=/chainconfig/rollup.json"
  if [ ! -f /chainconfig/rollup.json ]; then
    echo "Missing rollup.json file: Either update the repo to pull the published rollup.json or migrate your Celo L1 datadir to generate rollup.json."
    exit
  fi
else
  export EXTENDED_ARG="${EXTENDED_ARG:-} --network=$NETWORK_NAME --rollup.load-protocol-versions=true --rollup.halt=major"
fi

if [ -n $OP_NODE__P2P_ADVERTISE_IP ]; then
  export EXTENDED_ARG="${EXTENDED_ARG:-} --p2p.advertise.ip=$OP_NODE__P2P_ADVERTISE_IP"
fi

# OP_NODE_ALTDA_DA_SERVER is picked up by the op-node binary.
export OP_NODE_ALTDA_DA_SERVER=$EIGENDA_PROXY_ENDPOINT
if [ -z $OP_NODE_ALTDA_DA_SERVER ]; then
  OP_NODE_ALTDA_DA_SERVER="http://eigenda-proxy:4242"
fi

# Start op-node.
exec op-node \
  --l1=$OP_NODE__RPC_ENDPOINT \
  --l2=http://op-geth:8551 \
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
  --p2p.priv.path=/shared/op-node_p2p_priv.txt \
  $EXTENDED_ARG $@
