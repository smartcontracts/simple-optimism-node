#!/bin/bash

function extract() {
  rm -rf $2
  mkdir -p $2
  tar -xvf $1 -C $2
}

function copy() {
  BACKUP_DIR="/copy-backups/$1"
  mkdir -p $2
  mkdir -p $BACKUP_DIR
  rsync -avP --ignore-existing --backup --backup-dir="$BACKUP_DIR" "$1" "$2"
}

function torrent() {
  python3 ./scripts/torrent.py $1
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

function config() {
  echo "$(cast call 0xcbebc5ba53ff12165239cbb3d310fda2236d6ad2 'config(address,string)(string)' 0x68108902De3A5031197a6eB3b74b3b033e8E8e4d $1 --rpc-url https://goerli.infura.io/v3/84842078b09946638c03157f83405213)"
}
