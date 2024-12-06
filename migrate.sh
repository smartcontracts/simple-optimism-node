#!/bin/sh

set -e

# Function to display usage
usage() {
    echo "Usage: $0 <operation> <network> <source_dir> [destination_dir]"
    echo "  <operation>       Either pre or full"
    echo "  <network>         Network name (celo-mainnet, alfajores, or baklava)"
    echo "  <source_dir>      Source datadir directory (the value of the '--datadir' flag for the celo L1 client)"
    echo "  [destination_dir] Optional destination datadir directory (should be used as the value for the '--datadir'"
    echo "                    flag for the celo L2 client), if omitted './envs/<network>/datadir' will be used"
    exit 1
}

# Check the number of arguments
if [ "$#" -lt 3 ] || [ "$#" -gt 4 ]; then
    usage
fi

# Assign positional arguments to variables
operation=$1
network=$2
source_dir=$3
destination_dir="${4:-./envs/$network/datadir}"

# Validate the operation
if [ "$operation" != "pre" ] && [ "$operation" != "full" ]; then
    echo "Invalid operation: $operation"
    usage
fi

# Validate network name
if [ "$network" != "celo-mainnet" ] && [ "$network" != "alfajores" ] && [ "$network" != "baklava" ]; then
    echo "Invalid network name: $network"
    usage
fi

# Print parsed arguments
echo "Network: $network"
echo "Source Directory: $source_dir"
echo "Destination Directory: $destination_dir"

# Convert source and destination directories to absolute paths
source_dir=$(readlink -f "$source_dir")
destination_dir=$(readlink -f "$destination_dir")

# Ensure destination directory exists for chaindata
mkdir -p  "${destination_dir}/geth"

if [ "${operation}" = "pre" ]; then
  docker run --platform=linux/amd64 -it --rm \
    -v "${source_dir}/celo/chaindata:/old-db" \
    -v "${destination_dir}/geth/chaindata:/new-db" \
    us-west1-docker.pkg.dev/devopsre/celo-blockchain-public/cel2-migration-tool:5682b80ec60c47f582c6af8aa085ae6f9048d801 \
    "${operation}" \
      --old-db /old-db \
      --new-db /new-db
  exit 0
fi

# We need the OP_NODE__RPC_ENDPOINT to know where to connect to the L1 node.
. "${network}.env"

# Get MIGRATION_BLOCK_NUMBER and MIGRATION_BLOCK_TIME.
. "./envs/${network}/migration-config/migration.env"

# Gather required migration files
migration_config_dir="./envs/${network}/migration-config"
mkdir -p "$migration_config_dir"
(
  cd "$migration_config_dir"
  wget -N "https://storage.googleapis.com/cel2-rollup-files/${network}/config.json"
  wget -N "https://storage.googleapis.com/cel2-rollup-files/${network}/deployment-l1.json"                                                                              
  wget -N "https://storage.googleapis.com/cel2-rollup-files/${network}/l2-allocs.json"
)

docker run --platform=linux/amd64 -it --rm \
  -v "${source_dir}/celo/chaindata:/old-db" \
  -v "${destination_dir}/geth/chaindata:/new-db" \
  -v "${migration_config_dir}:/migration-config" \
  -v "./envs/${network}/config:/out-config" \
  us-west1-docker.pkg.dev/devopsre/celo-blockchain-public/cel2-migration-tool:5682b80ec60c47f582c6af8aa085ae6f9048d801 \
  "${operation}" \
    --old-db /old-db \
    --new-db /new-db \
    --deploy-config /migration-config/config.json \
    --l1-deployments /migration-config/deployment-l1.json \
    --l2-allocs /migration-config/l2-allocs.json \
    --l1-rpc "${OP_NODE__RPC_ENDPOINT}" \
    --outfile.rollup-config /out-config/rollup.json \
    --outfile.genesis /out-config/genesis.json \
    --migration-block-time="$MIGRATION_BLOCK_TIME" \
    --migration-block-number="$MIGRATION_BLOCK_NUMBER"

# Put a blank line before the summary
echo ""
# Use git to check if the rollup.json or genesis.json files have changed, if so then something went wrong with the migration.
# Note in the case that this is the first migration then the check will pass.
if git diff --quiet "./envs/${network}/config/rollup.json" "./envs/${network}/config/genesis.json"; then
    printf "\033[0;32mMigration successful\033[0m\n"
else
    printf "\033[0;31mMigration failed, output rollup.json and genesis.json do not match stored versions\033[0m\n"
    # Display the diff for the rollup.json and genesis.json files
    git diff "./envs/${network}/config/rollup.json" "./envs/${network}/config/genesis.json"
    exit 1
fi
