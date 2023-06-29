#!/bin/sh
set -eou

# Setting both endpoints doesn't hurt.
export DATA_TRANSPORT_LAYER__L1_RPC_ENDPOINT=$DATA_TRANSPORT_LAYER__RPC_ENDPOINT
export DATA_TRANSPORT_LAYER__L2_RPC_ENDPOINT=$DATA_TRANSPORT_LAYER__RPC_ENDPOINT

# Start the DTL.
exec node \
  dist/src/services/run.js \
  $@
