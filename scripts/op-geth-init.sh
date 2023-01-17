#!/bin/sh
set -exu

echo running "${0}"

function checksum() {
  if [ -d "$1" ]; then
    CHECKSUM=$(find $1 -type f -exec md5sum {} \; | awk '{print $1}' | md5sum | awk '{print $1}')
  else
    CHECKSUM=$(md5sum $1 | awk '{print $1}')
  fi

  if [ "$CHECKSUM" == "$2" ]; then
    return 0
  else 
    return 1
  fi
}

function downloaded() {
  if [ -e "$1" ]; then
    if checksum "$1" "$2"; then
      return 0
    else 
      return 1
    fi
  else
    return 1
  fi
}

function torrent() {
  echo "Downloading file..."
  cp $1 /watch/

  while true
  do
    if downloaded "$2" "$3"; then
      echo "Downloaded file"
      break
    else
      echo "Still downloading file..."
    fi

    sleep 5s
  done
}

GETH_DATA_DIR=/geth
TORRENTS_DIR=/torrents/$NETWORK_NAME

if ! command -v rsync &> /dev/null; then
  echo "Installing rsync..."
  apk add rsync
fi

if [ "$BEDROCK_SOURCE" == "download" ]; then
  BEDROCK_TAR_PATH=/downloads/bedrock.tar
  BEDROCK_TMP_PATH=/bedrock-tmp
  BEDROCK_BAK_PATH=/bedrock-bak

  if [ -e "$GETH_DATA_DIR" ] && [ -n "$(ls -A $GETH_DATA_DIR)" ]; then
    echo "Already initialized geth"
  else
    echo "Downloading bedrock.tar..."
    torrent $TORRENTS_DIR/bedrock.tar.torrent $BEDROCK_TAR_PATH $BEDROCK_TAR_CHECKSUM

    echo "Extracting bedrock.tar..."
    rm -rf $BEDROCK_TMP_PATH
    mkdir -p $BEDROCK_TMP_PATH
    tar -xvf $BEDROCK_TAR_PATH -C $BEDROCK_TMP_PATH

    echo "Initializing geth..."
    rsync -avP --ignore-existing --progress --backup --backup-dir="$BEDROCK_BAK_PATH" "$BEDROCK_TMP_PATH/geth" "$GETH_DATA_DIR"
  fi
fi

if [ "$BEDROCK_SOURCE" == "migration" ]; then
  WITNESS_TAR_PATH=/downloads/witness.tar
  WITNESS_OUT_PATH=/data/witness

  echo "Downloading witness.tar..."
  torrent $TORRENTS_DIR/witness.tar.torrent $WITNESS_TAR_PATH $WITNESS_TAR_CHECKSUM

  echo "Extracting witness.tar..."
  rm -rf $WITNESS_OUT_PATH
  mkdir -p $WITNESS_OUT_PATH
  tar -xvf $WITNESS_TAR_PATH -C $WITNESS_OUT_PATH

  # run the migration
  # copy the database into geth
fi

BEDROCK_JWT_PATH=/jwt/jwt.txt
if [ -e "$BEDROCK_JWT_PATH" ]; then
  echo "Already created jwt.txt"
else
  echo "JWT should've been created by op-node-init.sh"
  exit 1
fi
