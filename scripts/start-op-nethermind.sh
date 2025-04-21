#!/bin/bash
set -e

# Add debug information
echo "Debug: Checking Nethermind executable..."
ls -l /nethermind/Nethermind.Runner || echo "Nethermind.Runner not found in /nethermind/"
echo "Debug: Checking entire /nethermind directory..."
ls -la /nethermind/ || echo "/nethermind directory not found or empty"

# Wait for the Bedrock flag for this network to be set.
echo "Waiting for Bedrock node to initialize..."
while [ ! -f /shared/initialized.txt ]; do
  sleep 1
done

if [ ! -f /upgrade-pectra/upgraded ]; then
  echo "Please upgrade to Pectra with upgrade-pectra.sh"
  exit 1
fi

# Default configurations
NETHERMIND_DATA_DIR=${NETHERMIND_DATA_DIR:-/nethermind}
NETHERMIND_LOG_LEVEL=${NETHERMIND_LOG_LEVEL:-Info}

# Use environment variables from .env
RPC_PORT="${PORT__OP_NETHERMIND_HTTP:-8545}"
WS_PORT="${PORT__OP_NETHERMIND_WS:-8546}"
AUTHRPC_PORT="${PORT__OP_NETHERMIND_AUTHRPC:-8551}"
METRICS_PORT="${PORT__OP_NETHERMIND_METRICS:-6060}"
DISCOVERY_PORT="${PORT__OP_NETHERMIND_DISCOVERY:-30303}"

# Create necessary directories
mkdir -p "$NETHERMIND_DATA_DIR"

# Additional arguments based on environment variables
ADDITIONAL_ARGS=""

if [ -n "${OP_NETHERMIND_BOOTNODES:-}" ]; then
    ADDITIONAL_ARGS="$ADDITIONAL_ARGS --Network.Bootnodes=$OP_NETHERMIND_BOOTNODES"
fi

if [ -n "${OP_NETHERMIND_ETHSTATS_ENABLED:-}" ]; then
    ADDITIONAL_ARGS="$ADDITIONAL_ARGS --EthStats.Enabled=$OP_NETHERMIND_ETHSTATS_ENABLED"
fi

if [ -n "${OP_NETHERMIND_ETHSTATS_ENDPOINT:-}" ]; then
    ADDITIONAL_ARGS="$ADDITIONAL_ARGS --EthStats.NodeName=${OP_NETHERMIND_ETHSTATS_NODE_NAME:-NethermindNode} --EthStats.Endpoint=$OP_NETHERMIND_ETHSTATS_ENDPOINT"
fi

# Determine syncmode based on NODE_TYPE
if [ "$NODE_TYPE" = "full" ]; then
    ADDITIONAL_ARGS="$ADDITIONAL_ARGS --Sync.FastSync=true"
else
    ADDITIONAL_ARGS="$ADDITIONAL_ARGS --Sync.FastSync=false"
fi

# Execute Nethermind with properly formatted arguments
exec /nethermind/Nethermind.Runner \
    --config "$NETWORK_NAME" \
    --datadir "$NETHERMIND_DATA_DIR" \
    --Optimism.SequencerUrl "$BEDROCK_SEQUENCER_HTTP" \
    --log "$NETHERMIND_LOG_LEVEL" \
    --JsonRpc.Enabled true \
    --JsonRpc.Host 0.0.0.0 \
    --JsonRpc.WebSocketsPort "$WS_PORT" \
    --JsonRpc.Port "$RPC_PORT" \
    --JsonRpc.JwtSecretFile /shared/jwt.txt \
    --JsonRpc.EngineHost 0.0.0.0 \
    --JsonRpc.EnginePort "$AUTHRPC_PORT" \
    --JsonRpc.EnabledModules "Web3,Eth,Subscribe,Net,Engine" \
    --Network.DiscoveryPort "$DISCOVERY_PORT" \
    --Network.P2PPort "$DISCOVERY_PORT" \
    --HealthChecks.Enabled true \
    --Metrics.Enabled true \
    --Metrics.ExposePort "$METRICS_PORT" \
    $ADDITIONAL_ARGS
