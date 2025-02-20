#!/bin/bash

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
cel2_migration_tool_image="us-west1-docker.pkg.dev/devopsre/celo-blockchain-public/cel2-migration-tool:celo-migrate-v2.0.0-rc5"

# Run check-db continuity script to ensure source db has no data gaps
if docker run --platform=linux/amd64 -it --rm \
    -v "${source_dir}/celo/chaindata:/old-db" \
    "${cel2_migration_tool_image}" \
    check-db \
      --db-path /old-db \
      --fail-fast; then
    printf "\033[0;32mDB check completed successfully. No gaps or missing data detected.\033[0m\n"
else
    printf "\033[0;31mDB check failed with exit code $?. If the logs indicate that the db is missing data, please retry with another source db. You can visit https://docs.celo.org/cel2/operators/migrate-node for instructions on how to check whether a db has missing data.\033[0m\n"
    exit $?
fi

# Ensure destination directory exists for chaindata
mkdir -p  "${destination_dir}/geth/chaindata"

# Convert destination directory to absolute path
destination_dir=$(readlink -f "$destination_dir")

if [ "${operation}" = "pre" ]; then
  docker run --platform=linux/amd64 -it --rm \
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
