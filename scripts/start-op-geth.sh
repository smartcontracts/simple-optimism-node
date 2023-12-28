#!/bin/sh
set -eou

# Wait for the Bedrock flag for this network to be set.
while [ ! -f /shared/initialized.txt ]; do
  echo "Waiting for Bedrock node to initialize..."
  sleep 60
done

if [ -z "${IS_CUSTOM_CHAIN+x}" ]; then
  if [ "$NETWORK_NAME" == "op-mainnet" ] || [ "$NETWORK_NAME" == "op-goerli" ]; then
    export EXTENDED_ARG="${EXTENDED_ARG:-} --rollup.historicalrpc=${OP_GETH__HISTORICAL_RPC:-http://l2geth:8545} --op-network=$NETWORK_NAME"
  else
    export EXTENDED_ARG="${EXTENDED_ARG:-} --op-network=$NETWORK_NAME"
  fi
fi

# Init genesis if custom chain
if [ -n "${IS_CUSTOM_CHAIN+x}" ]; then
  geth init --datadir="$BEDROCK_DATADIR" /chainconfig/genesis.json
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
  --syncmode=full \
  --gcmode="$NODE_TYPE" \
  --nodiscover \
  --maxpeers=0 \
  --networkid=420 \
  --authrpc.vhosts="*" \
  --authrpc.addr=0.0.0.0 \
  --authrpc.port=8551 \
  --authrpc.jwtsecret=/shared/jwt.txt \
  --rollup.sequencerhttp="$BEDROCK_SEQUENCER_HTTP" \
  --rollup.disabletxpoolgossip=true \
  $EXTENDED_ARG $@

