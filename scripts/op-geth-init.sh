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

GETH_DATA_DIR=/geth

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
    if downloaded "$BEDROCK_TAR_PATH" "$BEDROCK_TAR_CHECKSUM"; then
      echo "Already downloaded bedrock.tar"
    else
      echo "Downloading bedrock.tar..."
      cp /torrents/$NETWORK_NAME/bedrock.tar.torrent /watch/

      while true
      do
        if downloaded "$BEDROCK_TAR_PATH" "$BEDROCK_TAR_CHECKSUM"; then
          echo "Downloaded bedrock.tar"
          break
        else
          echo "Still downloading bedrock.tar..."
        fi

        sleep 5s
      done
    fi

    echo "Extracting bedrock.tar..."
    rm -rf $BEDROCK_TMP_PATH
    mkdir -p $BEDROCK_TMP_PATH
    tar -xvf $BEDROCK_TAR_PATH -C $BEDROCK_TMP_PATH

    echo "Initializing geth..."
    rsync -avP --ignore-existing --progress --backup --backup-dir="$BEDROCK_BAK_PATH" "$BEDROCK_TMP_PATH/geth" "$GETH_DATA_DIR"
  fi
fi

BEDROCK_JWT_PATH=/jwt/jwt.txt
if [ -e "$BEDROCK_JWT_PATH" ]; then
  echo "Already created jwt.txt"
else
  echo "JWT should've been created by op-node-init.sh"
  exit 1
fi
