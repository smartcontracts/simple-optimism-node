#!/bin/bash

set -eu

# Load Environment Variables
if [ -f .env ]; then
  export $(cat .env | grep -v '#' | sed 's/\r$//' | awk '/=/ {print $1}' )
fi

export ETH_RPC_URL=http://localhost:${PORT__OP_GETH_HTTP:-9993}
# Cast is provided by Foundry: https://getfoundry.sh/.
# Run `pnpm install:foundry` in the optimism repo root.
CHAIN_ID=`cast chain-id`
echo Chain ID: $CHAIN_ID
echo Sampling, please wait

if [ $CHAIN_ID -eq 10 ]; then
  L2_URL=https://mainnet.optimism.io
fi

if [ $CHAIN_ID -eq 11155420 ]; then
  L2_URL=https://sepolia.optimism.io
fi

T0=`cast block-number --rpc-url $ETH_RPC_URL` ; sleep 10 ; T1=`cast block-number --rpc-url $ETH_RPC_URL`
PER_MIN=$(($T1 - $T0))
PER_MIN=$(($PER_MIN * 6))
echo Blocks per minute: $PER_MIN


if [ $PER_MIN -eq 0 ]; then
    echo Not syncing
    exit;
fi


# How many more blocks do we need?
HEAD=`cast block-number --rpc-url $L2_URL`
BEHIND=`expr $HEAD - $T1`
MINUTES=`expr $BEHIND / $PER_MIN`
HOURS=`expr $MINUTES / 60`

if [ $MINUTES -le 60 ] ; then
   echo Minutes until sync completed: $MINUTES
fi

if [ $MINUTES -gt 60 ] ; then
   echo Hours until sync completed: $HOURS
fi

if [ $HOURS -gt 24 ] ; then
   DAYS=`expr $HOURS / 24`
   echo Days until sync complete: $DAYS
fi
