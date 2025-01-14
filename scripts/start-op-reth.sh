#!/bin/bash
set -eu

RETH_DATA_DIR=/data
RPC_PORT="${RPC_PORT:-8545}"
WS_PORT="${WS_PORT:-8546}"
AUTHRPC_PORT="${AUTHRPC_PORT:-8551}"
METRICS_PORT="${METRICS_PORT:-6060}"

mkdir -p $RETH_DATA_DIR

exec op-reth node \
  --datadir="$RETH_DATA_DIR" \
  --log.stdout.format log-fmt \
  --ws \
  --ws.origins="*" \
  --ws.addr=0.0.0.0 \
  --ws.port="$WS_PORT" \
  --ws.api=debug,eth,net,txpool \
  --http \
  --http.corsdomain="*" \
  --http.addr=0.0.0.0 \
  --http.port="$RPC_PORT" \
  --http.api=debug,eth,net,txpool \
  --authrpc.addr=0.0.0.0 \
  --authrpc.port="$AUTHRPC_PORT" \
  --authrpc.jwtsecret=/shared/jwt.txt \
  --metrics=0.0.0.0:"$METRICS_PORT" \
  --chain "/chainconfig/genesis.json" \
  --rollup.sequencer-http=$BEDROCK_SEQUENCER_HTTP \
  --rollup.disable-tx-pool-gossip \
  --enable-discv5-discovery \
  --port="${PORT__OP_GETH_P2P:-39393}" \
