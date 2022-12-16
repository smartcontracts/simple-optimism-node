#!/bin/sh
set -exu

echo running "${0}"

GETH_DATA_DIR=/geth
GETH_CHAINDATA_DIR=$GETH_DATA_DIR/geth/chaindata
GETH_KEYSTORE_DIR=$GETH_DATA_DIR/keystore

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

if [ ! -d "$GETH_CHAINDATA_DIR" ]; then
    echo "$GETH_CHAINDATA_DIR missing, running init"
    geth init --datadir="$GETH_DATA_DIR" "$L2GETH_GENESIS_URL" "$L2GETH_GENESIS_HASH"
    echo "geth init complete"
else
    echo "$GETH_CHAINDATA_DIR exists, checking for hardfork."
    echo "Chain config:"
    geth dump-chain-cfg --datadir="$GETH_DATA_DIR"
fi
