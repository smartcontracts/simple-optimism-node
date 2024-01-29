#!/bin/bash

# extract: Extracts an archive into an output location.
# Arguments:
#   arc: Archive to to extract.
#   loc: Location to extract to.
function extract() {
  mkdir -p $2
  tar -xf $1 -C $2
}

# extract: Extracts a zst archive into an output location.
# Arguments:
#   arc: ZST archive to to extract.
#   loc: Location to extract to.
function extractzst() {
  mkdir -p $2
  tar --use-compress-program=unzstd -xf $1 -C $2
}

# extract: Extracts a lz4 archive into an output location.
# Arguments:
#   arc: lz4 archive to to extract.
#   loc: Location to extract to.
function extractlz4() {
  mkdir -p $2
  tar --use-compress-program="lz4 --no-crc" -xf $1 -C $2
}

# download: Downloads a file and provides basic progress percentages.
# Arguments:
#   url: URL of the file to download.
#   out: Location to download the file to.
function download() {
  aria2c --max-tries=0 -x 16 -s 16 -k100M -o $2 $1
}

# chainwait: Waits for a chain to be running.
# Arguments:
#   rpc: RPC URL of the chain to wait for.
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

# config: Grabs config from the Configuration contract on Goerli.
# Arguments:
#   cfg: Name of the configuration value to grab.
function config() {
  echo "$(cast call 0xcbebc5ba53ff12165239cbb3d310fda2236d6ad2 'config(address,string)(string)' 0x68108902De3A5031197a6eB3b74b3b033e8E8e4d $1 --rpc-url https://goerli.infura.io/v3/84842078b09946638c03157f83405213)"
}
