#!/bin/bash
set -exu

source ./scripts/init/utils.sh

install "go"
install "git"
install "make"
install "openssl"
install "cast"

# Common variables.
INITIALIZED_FLAG=/shared/initialized.txt
BEDROCK_JWT_PATH=/shared/jwt.txt
GETH_DATA_DIR=/geth
TORRENTS_DIR=/torrents/$NETWORK_NAME

# Exit early if we've already initialized.
if [ -e "$INITIALIZED_FLAG" ]; then
  echo "Bedrock node already initialized"
  exit 0
fi

# Wait for the Bedrock flag for this network to be set.
while true
do
  BEDROCK_FLAG=$(config "bedrock/$NETWORK_NAME/ready")
  if [ "$BEDROCK_FLAG" == "true" ]; then
    break
  else
    echo "Bedrock flag not set, waiting..."
    sleep 60
  fi
done

# Grab Bedrock network configuration values.
BEDROCK_TERMINAL_HEIGHT=$(config "bedrock/$NETWORK_NAME/terminal-height")
BEDROCK_TAR_MAGNET=$(config "bedrock/$NETWORK_NAME/bedrock-magnet")
WITNESS_TAR_MAGNET=$(config "bedrock/$NETWORK_NAME/witness-magnet")
BEDROCK_TAR_CHECKSUM=$(config "bedrock/$NETWORK_NAME/bedrock-checksum")
WITNESS_TAR_CHECKSUM=$(config "bedrock/$NETWORK_NAME/witness-checksum")

# Handle download.
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

# Handle migration.
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
      sleep 60
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

  echo "Cleaning up..."
  rm -rf $LEGACY_GETH_COPY_DIR
fi

# Create the JWT.
echo "Creating JWT..."
mkdir -p $(dirname $BEDROCK_JWT_PATH)
openssl rand -hex 32 > $BEDROCK_JWT_PATH

# Create the Bedrock flag to indicate that we've initialized.
echo "Creating Bedrock flag..."
touch $INITIALIZED_FLAG
