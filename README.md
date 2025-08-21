# Docker Compose Setup for Running a Celo L2 Node

A simple Docker Compose setup for running Celo L2 nodes with optional L1 data migration support.

> ⚠️ The instructions in this README are for illustrative purposes only. Please refer to the official [Celo Docs](https://docs.celo.org/cel2/operators/run-node) for the most up-to-date information on running Celo L2 nodes.

## Installation and Configuration

### Install Docker and Docker Compose

**Ubuntu/Linux:**

```sh
# Update and upgrade packages
sudo apt-get update && sudo apt-get upgrade -y

# Install prerequisites
sudo apt-get install -y curl gnupg ca-certificates lsb-release

#  Download the Docker GPG file to Ubuntu
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# Add Docker and Docker Compose support to Ubuntu's packages list
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update

# Install Docker and Docker Compose
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
sudo usermod -aG docker $(whoami)

# Verify installation
sudo docker run hello-world
```

> _For non-root users_:
> Log out and log back in after the installation to complete the setup. Test with:
>
> ```sh
> docker ps
> ```
>
> It should return an empty list without errors. If an error is returned, restart your machine.

**macOS:** Use [Docker Desktop](https://www.docker.com/products/docker-desktop/).
You may need to increase the virtual disk limit in Docker Desktop settings to accommodate the chaindata directory.This can be done by opening Docker Desktop, going to Settings -> Resources -> Advanced and increasing the disk image size.

**Windows:** Use [Docker Desktop](https://www.docker.com/products/docker-desktop/).

### Clone the Repository

```sh
git clone https://github.com/celo-org/celo-l2-node-docker-compose.git
cd celo-l2-node-docker-compose
```

### Configure Your Node

The easiest way to start a Celo L2 node is with **snap sync**.

1. **Choose your network** and copy the corresponding environment file:

   ```sh
   # Celo Sepolia is recommended for testing
   export NETWORK=<alfajores, baklava, celo-sepolia, or mainnet>
   cp $NETWORK.env .env
   ```

   The `.env` file contains all the necessary configuration options for your node and is pre-configured for snap sync and full (non-archive) mode.

2. **Configure P2P networking** (required for production):
   Edit your `.env` file and set these variables for external connectivity.

   ```text
   OP_NODE__P2P_ADVERTISE_IP=<your-public-ip>
   OP_GETH__NAT=extip:<your-public-ip>
   ```

3. **Optional: Configure L1 RPC endpoints**
   For better reliability, consider using paid RPC services instead of the defaults:

   ```text
   OP_NODE__RPC_ENDPOINT=<your-ethereum-rpc-url>
   OP_NODE__L1_BEACON=<your-ethereum-beacon-rpc-url>
   ```

## Advanced Node Configuration

### Key Environment Variables

- **NODE_TYPE**
  - `full` - A full node stores historical state only for recent blocks.
  - `archive` - An archive node stores historical state for the entire history of the blockchain.
- **OP_GETH__SYNCMODE** - Sync mode to use for L2 node
  - `snap` - Downloads chaindata from peers until it receives an unbroken chain of headers up through the most recent block, and only begins executing transactions from that point on.
  - `full` - Executes all transactions from genesis (or the last block in the datadir) to verify every header.
- **OP_NODE__RPC_ENDPOINT** - Layer 1 RPC endpoint (e.g., Ethereum mainnet). For reliability, use paid plans or self-hosted nodes.
- **OP_NODE__L1_BEACON** - Layer 1 beacon endpoint. For reliability, use paid plans or self-hosted nodes.
- **OP_NODE__RPC_TYPE** - Service provider type for the L1 RPC endpoint:
  - `alchemy` - Alchemy
  - `quicknode` - Quicknode (ETH only)
  - `erigon` - Erigon
  - `basic` - Other providers
- **HEALTHCHECK__REFERENCE_RPC_PROVIDER** - Public healthcheck RPC endpoint for the Layer 2 network.
- **HISTORICAL_RPC_DATADIR_PATH** - Datadir path to use for legacy archive node to serve pre-L2 historical state. If set, a Celo L1 node will be run in archive mode to serve requests requiring state for blocks prior to the L2 migration and op-geth will be configured to proxy those requests to the Celo L1 node.
- **OP_GETH__HISTORICAL_RPC** - RPC Endpoint for fetching pre-L2 historical state. If set, op-geth will proxy requests requiring state prior to the L2 hardfork there. If set, this overrides the use of a local Celo L1 node via **HISTORICAL_RPC_DATADIR_PATH**, which means that no local Celo L1 node will be run.
- **DATADIR_PATH** - Use a custom datadir instead of the default at `./envs/<network>/datadir`.
- **IPC_PATH** - Alternative location for the geth IPC file if filesystem compatibility issues occur.
- **IMAGE_TAG[...]__** - Use a custom Docker image for specified components.
- **MONITORING_ENABLED** - Enables the following services when set to `true`: `healthcheck`, `prometheus`, `grafana`, `influxdb`.

### Node Types and Sync Modes

The default configuration runs a snap sync full node, the fastest and easiest way to get started.
For advanced use cases, you can configure a different node type and sync mode.

- **Full sync node**: executes all transactions from genesis (or the last block in the datadir) to verify every header. Requires a migrated pre-migration datadir for complete historical verification. See the [L1 Data Migration](#l1-data-migration) section below.

   ```text
   NODE_TYPE=full
   OP_GETH__SYNCMODE=full
   DATADIR_PATH=<path to a migrated L1 full node datadir>
   ```

- **Archive node**: Stores complete historical state. Requires a migrated pre-migration datadir for complete historical verification. See the [L1 Data Migration](#l1-data-migration) section below.

   ```text
   NODE_TYPE=archive
   OP_GETH__SYNCMODE=full
   DATADIR_PATH=<path to a migrated L1 full node datadir>
   ```

  Additionnally, you need to configure pre-migration data access. You have 3 options:

  - Provide the path to an existing pre-migration archive datadir. The script will automatically start a legacy archive node with that datadir and connect it to your L2 node.

    ```text
    HISTORICAL_RPC_DATADIR_PATH=<path to your pre-migration archive datadir>
    ```
  
  - Not provide a path to an existing pre-migration archive datadir. The script will automatically start a legacy archive node which will begin syncing from the Celo genesis block. Note that syncing the legacy archive node will take some time, during which pre-migration archive access will not be available.

    ```text
    HISTORICAL_RPC_DATADIR_PATH=
    ```

  - Provide the RPC URL of a running legacy archive node. This will override any value set for HISTORICAL_RPC_DATADIR_PATH and a legacy archive node will not be launched when you start your L2 node.

    ```text
    OP_GETH__HISTORICAL_RPC=<historical rpc node endpoint>
    ```

### P2P Networking Environment Variables

> ⚠️ If these options are not configured correctly, your node will not be discoverable or reachable to other nodes on the network.

- **OP_NODE__P2P_ADVERTISE_IP** - Public IP to be shared via discovery so that other nodes can connect to your node.
- **PORT__OP_NODE_P2P** - Port for op-node P2P discovery. Defaults to `9222`.
- **OP_GETH__NAT** - Controls how op-geth determines its public IP. Use `extip:<your-public-ip>` for most reliable setup. Other values: `(any|none|upnp|pmp|pmp:<IP>|extip:<IP>|stun:<IP:PORT>)`.
- **PORT__OP_GETH_P2P** - Port for op-geth P2P discovery. Defaults to `30303`.
- **PORT[...]__** - Other custom ports that may be specified.

## Operating the Node

### Start

```sh
docker compose up -d --build
```

This will start the node in a detatched shell (`-d`), meaning the node will continue to run in the background. We recommended to add `--build` to make sure that latest changes are being applied.

### Stop

```sh
docker compose down
```

This will shut down the node without wiping any volumes. You can safely run this command and then restart the node again.

### Restart

```sh
docker compose restart
```

This will restart the node safely with minimal downtime but without upgrading the node.

### Upgrade

```sh
git pull
docker compose pull
docker compose up -d --build
```

This will pull the latest changes from GitHub and Docker Hub, rebuild the container, and start the node again.

### Wipe Data (⚠️ DANGER)

```sh
docker compose down -v
```

This will shut down the node and WIPE ALL DATA. Proceed with caution!

### Monitor

**View logs:**

```sh
# All containers
docker compose logs -f --tail 10

# Specific container
docker compose logs op-geth -f --tail 10
docker compose logs op-node -f --tail 10
docker compose logs eigenda-proxy -f --tail 10
```

**Check sync progress:**

```sh
# Install foundry: https://book.getfoundry.sh/getting-started/installation
./progress.sh
```

**Grafana Dashboard:**

If monitoring is enabled (`MONITORING_ENABLED=true`), Grafana is available at [http://localhost:3000](http://localhost:3000).

Login details:

- Username: `admin`
- Password: `optimism`

The "Simple Node Dashboard" (available at Dashboards > Manage > Simple Node Dashboard) shows basic node information and sync status.

![metrics dashboard gif](https://user-images.githubusercontent.com/14298799/171476634-0cb84efd-adbf-4732-9c1d-d737915e1fa7.gif)

---

## L1 Data Migration

> 💡 Most users should use snap sync (default) and skip this section. Migration is only needed for specific use cases requiring full historical verification or archive functionality.
>
> ⚠️ For detailed migration instructions, refer to the [official migration guide](https://docs.celo.org/cel2/operators/migrate-node). The instructions below are for reference only.

If you need to migrate existing Celo L1 data to L2, you have two options:

### Option 1: Download Pre-Migrated Data

Download migrated datadirs from the official sources listed in the [Celo Docs](https://docs.celo.org/cel2/operators/migrate-node).

### Option 2: Migrate Your Own Data

> ⚠️ IMPORTANT
>
> - Make sure your node is stopped before running the migration.
> - You should not attempt to migrate archive node data, only full node data.

If you've been running a full node and wish to continue using the same datadir, you can migrate the data as follows:

```sh
./migrate.sh full <network> <source_L1_datadir> [dest_L2_datadir]
```

Where `<network>` is one of `mainnet`, `alfajores` or `baklava` and the datadirs are the values that would be set with the `--datadir` flag in the celo-blockchain and the op-geth nodes.

If the destination datadir is omitted `./envs/<network>/datadir` will be used.

> ⚠️ When migrating a datadir, make sure to set `OP_GETH__SYNCMODE=full`, otherwise the node will use snap sync.

#### Troubleshooting

If you encounter this error during migration...

```log
CRIT [03-19|10:38:17.229] error in celo-migrate err="failed to run full migration: failed to get head header: failed to open database at \"/datadir/celo/chaindata\" err: failed to open leveldb: EOF"
```

...start up the celo-blockchain client with the same datadir, wait for it to fully load, then shut it down. This repairs inconsistent shutdown states.

Alternatively, open a console and exit:

```sh
geth console --datadir <datadir>
# Wait for console to load, then exit
```

It seems that this issue is caused by the celo-blockchain client sometimes shutting down in an inconsistent state, which is repaired upon the next startup.
