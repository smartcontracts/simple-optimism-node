#!/bin/sh
set -e

if [ "$NETWORK_NAME" != "alfajores" ] && [ "$NETWORK_NAME" != "baklava" ] && [ "$NETWORK_NAME" != "mainnet" ]; then
  echo "Not starting historical-rpc-node for a non migrated chain (${NETWORK_NAME})"
  exit
fi

if [ -n "${OP_GETH__HISTORICAL_RPC}" ]; then
  echo "Not starting historical-rpc-node, using an external historical RPC (${OP_GETH__HISTORICAL_RPC})"
  exit
fi

if [ -z "${HISTORICAL_RPC_DATADIR_PATH}" ]; then
  echo "Not starting historical-rpc-node since HISTORICAL_RPC_DATADIR_PATH is unset"
  exit
fi

METRICS_ARGS="--metrics"
if [ "$MONITORING_ENABLED" = "true" ]; then
  METRICS_ARGS="$METRICS_ARGS \
    --metrics.influxdb \
    --metrics.influxdb.endpoint=http://influxdb:8086 \
    --metrics.influxdb.database=historical-rpc-node"
fi

# Start historical-rpc-node.
exec geth \
  --$NETWORK_NAME \
  --datadir=$DATADIR \
  --gcmode=archive \
  --syncmode=full \
  $METRICS_ARGS \
  $@
