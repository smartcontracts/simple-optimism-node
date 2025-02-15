#!/bin/bash
set -e

# Import utilities.
source ./scripts/utils.sh

# Common variables.
INITIALIZED_FLAG=/shared/initialized.txt
BEDROCK_JWT_PATH=/shared/jwt.txt
GETH_DATA_DIR=$BEDROCK_DATADIR
TORRENTS_DIR=/torrents/$NETWORK_NAME
BEDROCK_TAR_PATH=/downloads/bedrock.tar
BEDROCK_TMP_PATH=/bedrock-tmp

# Exit early if we've already initialized.
if [ -e "$INITIALIZED_FLAG" ]; then
  echo "Bedrock node already initialized"
  exit 0
fi

echo "Bedrock node needs to be initialized..."
echo "Initializing via download..."

# Fix OP link with hardcoded official OP snapshot
echo "Fetching download link..."

if [ "$NODE_TYPE" = "full" ]; then
  # Warning: syncmode=full for syncing full node is deprecated and not recommended to use
  if [ "$OP_GETH__SYNCMODE" = "full" ]; then
    if [ "$NETWORK_NAME" = "op-mainnet" ]; then
      BEDROCK_TAR_DOWNLOAD="https://r2-snapshots.fastnode.io/op/$(curl -s https://r2-snapshots.fastnode.io/op/latest-mainnet)"
    elif [ "$NETWORK_NAME" = "op-goerli" ]; then
      BEDROCK_TAR_DOWNLOAD="https://datadirs.optimism.io/goerli-bedrock.tar.zst"
    fi
  fi
elif [ "$NODE_TYPE" = "archive" ]; then
  if [ "$NETWORK_NAME" = "op-mainnet" ]; then
    BEDROCK_TAR_DOWNLOAD="$(curl -s https://datadirs.optimism.io/latest/ | grep -oE 'https://[^\"]+')"
  elif [ "$NETWORK_NAME" = "base-mainnet" ]; then
    BEDROCK_TAR_DOWNLOAD="https://base-snapshots-mainnet-archive.s3.amazonaws.com/$(curl -s https://base-snapshots-mainnet-archive.s3.amazonaws.com/latest)"
  elif [ "$NETWORK_NAME" = "base-goerli" ]; then
    BEDROCK_TAR_DOWNLOAD="https://base-snapshots-goerli-archive.s3.amazonaws.com/$(curl -s https://base-snapshots-goerli-archive.s3.amazonaws.com/latest)"
  elif [ "$NETWORK_NAME" = "base-sepolia" ]; then
    BEDROCK_TAR_DOWNLOAD="https://base-snapshots-sepolia-archive.s3.amazonaws.com/$(curl -s https://base-snapshots-sepolia-archive.s3.amazonaws.com/latest)"
  fi
fi

if [ -n "$BEDROCK_TAR_DOWNLOAD" ]; then
  if [[ "$BEDROCK_TAR_DOWNLOAD" == *.zst ]]; then
    BEDROCK_TAR_PATH+=".zst"
  elif [[ "$BEDROCK_TAR_DOWNLOAD" == *.lz4 ]]; then
    BEDROCK_TAR_PATH+=".lz4"
  fi

  echo "Downloading bedrock.tar..."
  download $BEDROCK_TAR_DOWNLOAD $BEDROCK_TAR_PATH

  echo "Extracting bedrock.tar..."
  if [[ "$BEDROCK_TAR_DOWNLOAD" == *.zst ]]; then
    extractzst $BEDROCK_TAR_PATH $GETH_DATA_DIR
  elif [[ "$BEDROCK_TAR_DOWNLOAD" == *.lz4 ]]; then
    extractlz4 $BEDROCK_TAR_PATH $GETH_DATA_DIR
  else
    extract $BEDROCK_TAR_PATH $GETH_DATA_DIR
  fi

  # Remove tar file to save disk space
  rm $BEDROCK_TAR_PATH
fi

echo "Creating JWT..."
mkdir -p $(dirname $BEDROCK_JWT_PATH)
openssl rand -hex 32 > $BEDROCK_JWT_PATH

echo "Creating Bedrock flag..."
touch $INITIALIZED_FLAG
touch /upgrade-pectra/upgraded
