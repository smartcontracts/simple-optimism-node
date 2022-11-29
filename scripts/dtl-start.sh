#!/bin/sh
set -eou

# Setting both endpoints doesn't hurt
export DATA_TRANSPORT_LAYER__L1_RPC_ENDPOINT=$DATA_TRANSPORT_LAYER__RPC_ENDPOINT
export DATA_TRANSPORT_LAYER__L2_RPC_ENDPOINT=$DATA_TRANSPORT_LAYER__RPC_ENDPOINT

# Set the backend depending on given sync source
export DATA_TRANSPORT_LAYER__DEFAULT_BACKEND=$SYNC_SOURCE
export DATA_TRANSPORT_LAYER__L1_GAS_PRICE_BACKEND=$SYNC_SOURCE

# Also tell the DTL to sync from the right place
if [ $SYNC_SOURCE == "l1" ]; then
  export DATA_TRANSPORT_LAYER__SYNC_FROM_L1=true
  export DATA_TRANSPORT_LAYER__SYNC_FROM_L2=false
else
  export DATA_TRANSPORT_LAYER__SYNC_FROM_L1=false
  export DATA_TRANSPORT_LAYER__SYNC_FROM_L2=true
fi

# Run the DTL
exec node \
  dist/src/services/run.js \
  $@
