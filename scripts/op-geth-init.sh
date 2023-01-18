#!/bin/sh
set -exu

source ./utils.sh

install "rsync"
install "go"
install "git"
install "make"
install "curl"

BEDROCK_JWT_PATH=/jwt/jwt.txt
GETH_DATA_DIR=/geth
TORRENTS_DIR=/torrents/$NETWORK_NAME

if [ -e "$GETH_DATA_DIR" ] && [ -n "$(ls -A $GETH_DATA_DIR)" ]; then
  echo "Already initialized geth"
else
  if [ "$BEDROCK_SOURCE" == "download" ]; then
    BEDROCK_TAR_PATH=/downloads/bedrock.tar
    BEDROCK_TMP_PATH=/bedrock-tmp

    echo "Downloading bedrock.tar..."
    torrent $TORRENTS_DIR/bedrock.tar.torrent $BEDROCK_TAR_PATH $BEDROCK_TAR_CHECKSUM

    echo "Extracting bedrock.tar..."
    extract $BEDROCK_TAR_PATH $BEDROCK_TMP_PATH

    echo "Initializing geth..."
    copy $BEDROCK_TMP_PATH/geth $GETH_DATA_DIR
  fi

  if [ "$BEDROCK_SOURCE" == "migration" ]; then
    LEGACY_GETH_DATA_DIR=/legacy-geth/geth
    LEGACY_GETH_COPY_DIR=/legacy-geth-copy
    WITNESS_TAR_PATH=/downloads/witness.tar
    WITNESS_OUT_PATH=/data/witness

    echo "Waiting for l2geth..."
    chainwait "http://l2geth:8545"

    echo "Waiting for l2geth to be at terminal height..."
    while true
    do
      if [ $(blocknum "http://l2geth:8545") -eq $TERMINAL_HEIGHT ]; then
        break
      else
        echo "Still waiting for l2geth to be at terminal height..."
        sleep 5
      fi
    done

    echo "Downloading witness.tar..."
    torrent $TORRENTS_DIR/witness.tar.torrent $WITNESS_TAR_PATH $WITNESS_TAR_CHECKSUM

    echo "Extracting witness.tar..."
    extract $WITNESS_TAR_PATH $WITNESS_OUT_PATH

    echo "Duplicating legacy geth dir..."
    copy $LEGACY_GETH_DATA_DIR $LEGACY_GETH_COPY_DIR

    echo "Cloning optimism monorepo..."
    rm -rf optimism
    git clone https://github.com/ethereum-optimism/optimism.git

    echo "Building migration script..."
    cd optimism/op-chain-ops
    make op-migrate

    echo "Running migration script..."
    ./bin/op-migrate \
      --l1-rpc-url $OP_NODE__RPC_ENDPOINT \
      --ovm-addresses $WITNESS_OUT_PATH/data/ovm-addresses.json \
      --evm-addresses $WITNESS_OUT_PATH/data/evm-addresses.json \
      --ovm-messages $WITNESS_OUT_PATH/data/ovm-messages.json \
      --evm-messages $WITNESS_OUT_PATH/data/evm-messages.json \
      --ovm-allowances $WITNESS_OUT_PATH/data/ovm-allowances.json \
      --network $NETWORK_NAME \
      --deploy-config ../packages/contracts-bedrock/deploy-config/$NETWORK_NAME.json \
      --hardhat-deployments ../packages/contracts-bedrock/deployments,../packages/contracts/deployments,../packages/contracts-periphery/deployments \
      --db-path $LEGACY_GETH_COPY_DIR

    echo "Initializing geth..."
    copy $LEGACY_GETH_COPY_DIR/geth $GETH_DATA_DIR
  fi
fi

if [ -e "$BEDROCK_JWT_PATH" ]; then
  echo "Already created jwt.txt"
else
  echo "JWT should've been created by op-node-init.sh"
  exit 1
fi
