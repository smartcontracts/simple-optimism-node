#!/bin/sh
set -e

if [ "$NETWORK_NAME" != "op-mainnet" ]; then
  echo "Stopping l2geth for a non op-mainnet chain"
  exit
fi

if [ -n "${OP_GETH__HISTORICAL_RPC}" ]; then
  echo "Stopping l2geth for using an external historical RPC"
  exit
fi

# l2geth new standard env variables
export USING_OVM=true
export ETH1_SYNC_SERVICE_ENABLE=false
export RPC_API=eth,rollup,net,web3,debug
export RPC_ADDR=0.0.0.0
export RPC_CORS_DOMAIN=*
export RPC_ENABLE=true
export RPC_PORT=8545
export RPC_VHOSTS=*

# Start l2geth.
exec geth --datadir=$DATADIR $@
