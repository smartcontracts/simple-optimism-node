#!/bin/sh

set -e

# Function to display usage
usage() {
    echo "Usage: $0 <operation> <network> <source_dir> [destination_dir]"
    echo "  <operation>       Either pre or full"
    echo "  <network>         Network name (mainnet, alfajores, or baklava)"
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
if [ "$network" != "mainnet" ] && [ "$network" != "alfajores" ] && [ "$network" != "baklava" ]; then
    echo "Invalid network name: $network"
    usage
fi

# Print parsed arguments
echo "Network: $network"
echo "Source Directory: $source_dir"
echo "Destination Directory: $destination_dir"
echo "" # Blank line to separate from any failure output

# Check if source directory exists
if [ ! -d "${source_dir}" ]; then
    printf "\033[0;31mError: Source directory does not exist\033[0m\n"
    exit 1
fi

# Convert source directory to absolute path
source_dir=$(readlink -f "$source_dir")
cel2_migration_tool_image="us-west1-docker.pkg.dev/devopsre/celo-blockchain-public/cel2-migration-tool:celo-migrate-v2.0.1"

# Ensure destination directory exists for chaindata
mkdir -p  "${destination_dir}/geth/chaindata"

# Convert destination directory to absolute path
destination_dir=$(readlink -f "$destination_dir")

if [ "${operation}" = "pre" ]; then
  docker run -it --rm \
    -v "${source_dir}/celo/chaindata:/old-db" \
    -v "${destination_dir}/geth/chaindata:/new-db" \
    "${cel2_migration_tool_image}" \
    "${operation}" \
      --old-db /old-db \
      --new-db /new-db
  exit 0
fi

# We need the OP_NODE__RPC_ENDPOINT to know where to connect to the L1 node.
if ! test -e "${network}.env"; then
	echo "Network environment file not found: ${network}.env"
	echo "If this repo is up to date with the remote main branch, then the ${network} config has not yet been published."
fi
. "./${network}.env"

# For mainnet we set the L1_BEACON_RPC_FLAG to be able to dynamically find the l1 starting block tag
if [ "$network" = "mainnet" ]; then
	L1_BEACON_RPC_FLAG="--l1-beacon-rpc=$OP_NODE__L1_BEACON"
fi

# Get MIGRATION_BLOCK_NUMBER.
. "./envs/${network}/migration-config/migration.env"

# Gather required migration files
migration_config_dir="./envs/${network}/migration-config"
mkdir -p "$migration_config_dir"
if ! (
  networkid=${network}
  if [ ${network} = "mainnet" ]; then
	  networkid="celo"
  fi
  cd "$migration_config_dir"
  wget -O config.json "https://storage.googleapis.com/cel2-rollup-files/${networkid}/config.json"
  wget -O deployment-l1.json "https://storage.googleapis.com/cel2-rollup-files/${networkid}/deployment-l1.json"
  wget -O l2-allocs.json "http://storage.googleapis.com/cel2-rollup-files/${networkid}/l2-allocs.json"
); then
  printf "\033[0;31mFailed to download migration config: one or more downloads failed. You may need to wait until the migration config has been published.\033[0m\n"
  exit 1
fi


docker run -it --rm \
  -v "${source_dir}/celo/chaindata:/old-db" \
  -v "${destination_dir}/geth/chaindata:/new-db" \
  -v "${migration_config_dir}:/migration-config" \
  -v "./envs/${network}/config:/out-config" \
  "${cel2_migration_tool_image}" \
  "${operation}" \
    --old-db /old-db \
    --new-db /new-db \
    --deploy-config /migration-config/config.json \
    --l1-deployments /migration-config/deployment-l1.json \
    --l2-allocs /migration-config/l2-allocs.json \
    --l1-rpc "${OP_NODE__RPC_ENDPOINT}" \
    --outfile.rollup-config /out-config/rollup.json \
    --outfile.genesis /out-config/genesis.json \
    --migration-block-number="$MIGRATION_BLOCK_NUMBER" "$L1_BEACON_RPC_FLAG"

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
