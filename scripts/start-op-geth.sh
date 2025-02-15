#!/bin/sh
set -e

# Wait for the Bedrock flag for this network to be set.
echo "Waiting for Bedrock node to initialize..."
while [ ! -f /shared/initialized.txt ]; do
  sleep 1
done

if [ ! -f /upgrade-pectra/upgraded ]; then
  echo "Please upgrade to Pectra with upgrade-pectra.sh"
  exit 1
fi

if [ -z "${IS_CUSTOM_CHAIN}" ]; then
  if [ "$NETWORK_NAME" == "op-mainnet" ] || [ "$NETWORK_NAME" == "op-goerli" ]; then
    export EXTENDED_ARG="${EXTENDED_ARG:-} --rollup.historicalrpc=${OP_GETH__HISTORICAL_RPC:-http://l2geth:8545} --op-network=$NETWORK_NAME"
  else
    export EXTENDED_ARG="${EXTENDED_ARG:-} --op-network=$NETWORK_NAME"
  fi
fi

# Init genesis if custom chain
if [ -n "${IS_CUSTOM_CHAIN}" ]; then
  geth init --datadir="$BEDROCK_DATADIR" /chainconfig/genesis.json
fi

# Determine syncmode based on NODE_TYPE
if [ -z "$OP_GETH__SYNCMODE" ]; then
  if [ "$NODE_TYPE" = "full" ]; then
    export OP_GETH__SYNCMODE="snap"
  else
    export OP_GETH__SYNCMODE="full"
  fi
fi

# Start op-geth.
exec geth \
  --datadir="$BEDROCK_DATADIR" \
  --http \
  --http.corsdomain="*" \
  --http.vhosts="*" \
  --http.addr=0.0.0.0 \
  --http.port=8545 \
  --http.api=web3,debug,eth,txpool,net,engine \
  --ws \
  --ws.addr=0.0.0.0 \
  --ws.port=8546 \
  --ws.origins="*" \
  --ws.api=debug,eth,txpool,net,engine,web3 \
  --metrics \
  --metrics.influxdb \
  --metrics.influxdb.endpoint=http://influxdb:8086 \
  --metrics.influxdb.database=opgeth \
  --syncmode="$OP_GETH__SYNCMODE" \
  --gcmode="$NODE_TYPE" \
  --authrpc.vhosts="*" \
  --authrpc.addr=0.0.0.0 \
  --authrpc.port=8551 \
  --authrpc.jwtsecret=/shared/jwt.txt \
  --rollup.sequencerhttp="$BEDROCK_SEQUENCER_HTTP" \
  --rollup.disabletxpoolgossip=true \
  --port="${PORT__OP_GETH_P2P:-39393}" \
  --discovery.port="${PORT__OP_GETH_P2P:-39393}" \
  --db.engine=pebble \
  --state.scheme=hash \
  $EXTENDED_ARG $@

