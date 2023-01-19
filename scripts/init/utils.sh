#!/bin/bash

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
    if [ "$1" == "cast" ]; then
      install "curl"
      install "git"
      curl -L https://foundry.paradigm.xyz | bash
      /root/.foundry/bin/foundryup
      cp /root/.foundry/bin/cast /usr/local/bin/cast
    elif [ "$1" == "go" ]; then
      install "curl"
      curl -OL https://golang.org/dl/go1.19.5.linux-amd64.tar.gz
      tar -C /usr/local -xzf go1.19.5.linux-amd64.tar.gz
      cp /usr/local/go/bin/go /usr/local/bin/go
    else
      apt-get update && apt-get install $1 --assume-yes
    fi
  fi
}

function chainwait() {
  install "curl"
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

function copy() {
  install "rsync"
  BACKUP_DIR="/copy-backups/$1"
  mkdir -p $2
  mkdir -p $BACKUP_DIR
  rsync -avP --ignore-existing --progress --backup --backup-dir="$BACKUP_DIR" "$1" "$2"
}

function blocknum() {
  install "cast"
  echo "$(cast block-number --rpc-url $1)"
}

function config() {
  install "cast"
  echo "$(cast call 0xcbebc5ba53ff12165239cbb3d310fda2236d6ad2 'config(address,string)(string)' 0x68108902De3A5031197a6eB3b74b3b033e8E8e4d $1 --rpc-url https://goerli.infura.io/v3/84842078b09946638c03157f83405213)"
}
