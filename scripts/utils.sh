#!/bin/sh

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
  cp $1 /watch/

  while true
  do
    if downloaded "$2" "$3"; then
      break
    else
      echo "Still downloading file..."
    fi

    sleep 5s
  done
}

function extract() {
  rm -rf $2
  mkdir -p $2
  tar -xvf $1 -C $2
}

function install() {
  if ! command -v $1 &> /dev/null; then
    echo "Installing $1..."
    apk add $1
  fi
}

function chainwait() {
  curl \
    -X POST \
    --silent \
    --output /dev/null \
    --retry-connrefused \
    --retry 1000 \
    --retry-delay 1 \
    -d '{"jsonrpc":"2.0","id":0,"method":"eth_chainId","params":[]}' \
    $1
}

function blocknum() {
  RESULT=$(curl -X POST -s -d '{"jsonrpc":"2.0","id":0,"method":"eth_blockNumber","params":[]}' $1 | jq -r '.result')
  echo $(($RESULT))
}

function copy() {
  BACKUP_DIR="/copy-backups/$1"
  mkdir -p $2
  mkdir -p $BACKUP_DIR
  rsync -avP --ignore-existing --progress --backup --backup-dir="$BACKUP_DIR" "$1" "$2"
}
