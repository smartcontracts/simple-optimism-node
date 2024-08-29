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

GETH_DATA_DIR=/geth
GETH_CHAINDATA_DIR=$GETH_DATA_DIR/geth/chaindata
GETH_KEYSTORE_DIR=$GETH_DATA_DIR/keystore

# Initialize keystore directory if necessary.
if [ ! -d "$GETH_KEYSTORE_DIR" ]; then
  echo "$GETH_KEYSTORE_DIR missing, running account import"
  echo -n "$BLOCK_SIGNER_PRIVATE_KEY_PASSWORD" > "$GETH_DATA_DIR"/password
  echo -n "$BLOCK_SIGNER_PRIVATE_KEY" > "$GETH_DATA_DIR"/block-signer-key
  geth account import \
    --datadir="$GETH_DATA_DIR" \
    --password="$GETH_DATA_DIR"/password \
    "$GETH_DATA_DIR"/block-signer-key
  echo "get account import complete"
fi

# Initialize chaindata directory if necessary.
if [ ! -d "$GETH_CHAINDATA_DIR" ]; then
  echo "$GETH_CHAINDATA_DIR missing, running init"
  geth init --datadir="$GETH_DATA_DIR" "$L2GETH_GENESIS_URL" "$L2GETH_GENESIS_HASH"
  echo "geth init complete"
fi
