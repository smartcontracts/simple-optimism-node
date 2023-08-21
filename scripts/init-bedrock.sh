#!/bin/bash
set -eou

# Import utilities.
source ./scripts/utils.sh

# Common variables.
INITIALIZED_FLAG=/shared/initialized.txt
BEDROCK_JWT_PATH=/shared/jwt.txt
GETH_DATA_DIR=/geth
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

echo "Fetching download link..."
BEDROCK_TAR_DOWNLOAD=$(config "bedrock/$NETWORK_NAME/bedrock-download")

echo "Downloading bedrock.tar..."
aria2c -x 4 -s 4 -j 4 -o $BEDROCK_TAR_PATH $BEDROCK_TAR_DOWNLOAD

echo "Extracting bedrock.tar..."
extract $BEDROCK_TAR_PATH $GETH_DATA_DIR

echo "Creating JWT..."
mkdir -p $(dirname $BEDROCK_JWT_PATH)
openssl rand -hex 32 > $BEDROCK_JWT_PATH

echo "Creating Bedrock flag..."
touch $INITIALIZED_FLAG
