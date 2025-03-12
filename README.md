# Docker Compose Setup for Running a Celo L2 Node

A simple docker compose script for migrating Celo L1 data and launching Celo L2 nodes.

> ⚠️ The instructions in this README are are for illustrative purposes only. Please refer to the [Celo Docs](https://docs.celo.org/cel2/notices/l2-migration) for the most up to date information on participating in the L2 hardfork.

## Installation and Configuration

### Install docker and docker compose

> Note: If you're not logged in as root, you'll need to log out and log in again after installation to complete the docker installation.

This command installs docker and docker compose for Ubuntu. For windows and mac, please use Docker Desktop. For all other OS, please find instructions online.

```sh
# Update and upgrade packages
sudo apt-get update
sudo apt-get upgrade -y

### Docker and docker compose prerequisites
sudo apt-get install -y curl
sudo apt-get install -y gnupg
sudo apt-get install -y ca-certificates
sudo apt-get install -y lsb-release

### Download the docker gpg file to Ubuntu
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

### Add Docker and docker compose support to the Ubuntu's packages list
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update
 
### Install docker and docker compose on Ubuntu
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

sudo usermod -aG docker $(whoami)
 
### Verify the Docker and docker compose install on Ubuntu
sudo docker run hello-world
```

(For non-root user) After logging out and in, test if docker is working by running.

```sh
docker ps
```

This should return an empty container list. If an error is returned, restart your machine.

### MacOS configure virtual disk limit

If using Docker Desktop on MacOS you will most likely need to increase the virtual disk limit in order to accomodate the chaindata directory. This can be done by opening Docker Desktop, going to Settings -> Resources -> Advanced and increasing the disk image size.

### Clone the Repository

```sh
git clone https://github.com/celo-org/celo-l2-node-docker-compose.git
cd celo-l2-node-docker-compose
```

## Configuring a node

Example configs are provided for Alfajores, Baklava and Mainnet. Start by copying the desired network environment file to `.env`, which is what docker-compose will use to load environment variables.

E.g. to run a node on Alfajores:

```sh
cp alfajores.env .env
```

The `.env` file is now ready to use and configured for snap sync and full (non-archive) mode. If you would like to customise your node further see below.

### Node configurations

We recommend one of the 3 following configurations for your L2 node. For more detailed instructions on running Celo nodes, see the [Running a Celo Node](https://docs.celo.org/cel2/operators/run-node) docs page.

1. Snap sync node:

    No extra requirements, simply use the provided default config for the appropriate network. Your node will use snap sync to download chaindata from the p2p network and will run as a full node, meaning that it will not store archive state. This is the easiest way to start your node as you do not need a migrated pre-hardfork datadir.
  
2. Full sync node:

    Requires a migrated pre-hardfork full node datadir (you should not run the migration on an archive datadir).

      ```text
      OP_GETH__SYNCMODE=full
      DATADIR_PATH=<path to your migrated pre-hardfork full node datadir>
      ```

3. Archive node:

    > ⚠️ We do not recommend migrating archive data. Please only migrate full node data, even if you plan to run an archive node. See the [migration docs](https://docs.celo.org/cel2/operators/migrate-node) for more information.

    Celo L2 nodes cannot use pre-hardfork state. Therefore, RPC requests requiring state (e.g. `eth_call`, `eth_getBalance`) from before the L2 hardfork require access to a running legacy archive node. Your Celo L2 node can be easily configured to forward requests requiring pre-hardfork state to a legacy archive node.

    The tooling in this repo makes running a Celo L2 archive node setup straightforward. You have 3 options:

      1. Run your L2 node in archive mode with full sync, and provide the path to an existing pre-hardfork archive datadir. The docker-compose script will then automatically start a legacy archive node with that datadir and connect it to your L2 node.

          ```text
          NODE_TYPE=archive
          OP_GETH__SYNCMODE=full
          DATADIR_PATH=<path to a migrated L1 full node datadir>
          HISTORICAL_RPC_DATADIR_PATH=<path to your pre-hardfork archive datadir>
          ```

      2. Run your L2 node in archive mode with full sync, and do not provide a path to an existing pre-hardfork archive datadir. The docker-compose script will automatically start a legacy archive node which will begin syncing from the Celo genesis block. Note that syncing the legacy archive node will take some time, during which pre-hardfork archive access will not be available.

          ```text
          NODE_TYPE=archive
          OP_GETH__SYNCMODE=full
          DATADIR_PATH=<path to a migrated L1 full node datadir>
          HISTORICAL_RPC_DATADIR_PATH=
          ```

      3. Run your L2 node in archive mode with full sync, and provide the RPC url of a running legacy archive node. This will override any value set for `HISTORICAL_RPC_DATADIR_PATH` and a legacy archive node will not be launched when you start your L2 node.

          ```text
          NODE_TYPE=archive
          OP_GETH__SYNCMODE=full
          DATADIR_PATH=<path to a migrated L1 full node datadir>
          OP_GETH__HISTORICAL_RPC=<historical rpc node endpoint>
          ```

    Note that in all of these configurations we set

      ```text
      NODE_TYPE=archive
      OP_GETH__SYNCMODE=full
      ```

    This is because nodes will not accept requests for RPC methods that require archive state data unless we set `NODE_TYPE=archive`, and because archive nodes that use snap sync do not store state until the block at which they finish syncing. For these reasons, we recommend using the configurations above. See below for more information.

### Environment Variables

- **NODE_TYPE**
  - `full` - A full node stores historical state only for recent blocks.
  - `archive` - An archive node stores historical state for the entire history of the blockchain.
- **OP_GETH__SYNCMODE** - Sync mode to use for L2 node
  - `snap` - If left empty, `snap` sync will be used. `snap` sync downloads chaindata from peers until it receives an unbroken chain of headers up through the most recent block, and only begins executing transactions from that point on. Archive nodes that run with `snap` sync will only store state from the point at which the node begins executing transactions.
  - `full` - `full` sync executes all transactions from genesis (or the last block in the datadir) to verify every header. Archive nodes that run with `full` sync will store state for every block synced, as `full` sync must calculate the state at every block in order to verify every header.
- **OP_NODE__RPC_ENDPOINT** - Specify the Layer 1 RPC endpoint (e.g., Ethereum mainnet). For instance, you can use the Alchemy free plan for Ethereum mainnet.
- **OP_NODE__L1_BEACON** - Specify the Layer 1 beacon endpoint. For instance, you can use [QuickNode](https://www.quicknode.com). E.g `https://xxx-xxx-xxx.quiknode.pro/db55a3908ba7e4e5756319ffd71ec270b09a7dce`.
- **OP_NODE__RPC_TYPE** - Specify the service provider for the RPC endpoint you've chosen in the previous step. The available options are:
  - `alchemy` - Alchemy
  - `quicknode` - Quicknode (ETH only)
  - `erigon` - Erigon
  - `basic` - Other providers
- **HEALTHCHECK__REFERENCE_RPC_PROVIDER** - Specify the public healthcheck RPC endpoint for the Layer 2 network.
- **HISTORICAL_RPC_DATADIR_PATH** - Datadir path to use for legacy archive node to serve pre-L2 historical state.
- **OP_GETH__HISTORICAL_RPC** - RPC Endpoint for fetching pre-L2 historical state. If set, this overrides the **HISTORICAL_RPC_DATADIR_PATH** setting.
- **IMAGE_TAG**[...]__ - Use custom docker image for specified components.
- **PORT**[...]__ - Use custom port for specified components.

## Obtaining a migrated datadir

If you are not using `snap` sync, then a migrated pre-hardfork full node datadir is required. Your options for obtaining one are as follows.

> ⚠️ The instructions in this README are are for illustrative purposes only. Please refer to [Migrating a Celo L1 node](https://docs.celo.org/cel2/operators/migrate-node) for the most up to date information.

### 1. Download a migrated datadir

If you do not have an existing pre-hardfork full node datadir but wish to full sync or run an archive node you can download a migrated datadir hosted by cLabs from one of the links provided in [Migrating a Celo L1 node](https://docs.celo.org/cel2/operators/migrate-node).

### 2. Migrate your own datadir

> ⚠️ We do not recommend migrating archive data. Please only migrate full node data, even if you plan to run an archive node. See [Migrating a Celo L1 node](https://docs.celo.org/cel2/operators/migrate-node) for more information.

If you've been running a full node and wish to continue using the same datadir, you can migrate the data as follows:

```sh
./migrate.sh full <network> <source_L1_chaindata_dir> [dest_L2_chaindata_dir2]
```

Where `<network>` is one of `mainnet`, `alfajores` or `baklava`.

Please make sure your node is stopped before running the migration.

If the destination dir is omitted `./envs/<network>/datadir` will be used.

#### Pre-migrations

In the case that you wish to suffer minimal downtime at the L2 hardfork point you can run a pre-migration which will allow the bulk of a migration to occur in advance, thus speeding up the final full migration.

Note your node needs to be stopped in order for the pre-migration to be run.

To run a pre-migration use the following command:

```sh
./migrate.sh pre <network> <source_L1_chaindata_dir> [dest_L2_chaindata_dir2]
```

Also note that the full migration needs to be run with the same destination dir
as the pre-migration in order to benefit from the pre-migration.

There is no limit to the number of times a pre-migration can be run, each
subsequent run of a pre-migration will migrate the blocks added since the
previous pre-migration.

## Operating the Node

### Start

```sh
docker compose up -d --build
```

Will start the node in a detatched shell (`-d`), meaning the node will continue to run in the background. We recommended to add `--build` to make sure that latest changes are being applied.

### View logs

To view logs of all containers, run

```sh
docker compose logs -f --tail 10
```

To view logs for a specific container, run

```sh
docker compose logs [CONTAINER_NAME] -f --tail 10
```

Where `CONTAINER_NAME` will most likely be one of:

- op-geth
- op-node
- historical-rpc-node
- eigenda-proxy

Refer to the docker-compose file for the full list of containers.

### Stop

```sh
docker compose down
```

Will shut down the node without wiping any volumes.
You can safely run this command and then restart the node again.

### Restart

```sh
docker compose restart
```

Will restart the node safely with minimal downtime but without upgrading the node.

### Upgrade

Pull the latest updates from GitHub, and Docker Hub and rebuild the container.

```sh
git pull
docker compose pull
docker compose up -d --build
```

Will upgrade your node with minimal downtime.

### Wipe [DANGER]

```sh
docker compose down -v
```

Will shut down the node and WIPE ALL DATA. Proceed with caution!

## Monitoring

### Conditional Start of Monitoring Services

The following monitoring-related services:

- `healthcheck`
- `prometheus`
- `grafana`
- `influxdb`

will only start if the environment variable `MONITORING_ENABLED` is set to `true`

### Estimate remaining sync time

To estimate remaining sync time, first [install foundry](https://book.getfoundry.sh/getting-started/installation) and then run

```sh
./progress.sh
```

This will display remaining sync time and sync speed in blocks per minute.

```text
Chain ID: 10
Please wait
Blocks per minute: ...
Hours until sync completed: ...
```

### Grafana dashboard

Grafana is exposed at [http://localhost:3000](http://localhost:3000) and comes with one pre-loaded dashboard ("Simple Node Dashboard").
Simple Node Dashboard includes basic node information and will tell you if your node ever falls out of sync with the reference L2 node or if a state root fault is detected.

Use the following login details to access the dashboard:

- Username: `admin`
- Password: `optimism`

Navigate over to `Dashboards > Manage > Simple Node Dashboard` to see the dashboard, see the following gif if you need help:

![metrics dashboard gif](https://user-images.githubusercontent.com/14298799/171476634-0cb84efd-adbf-4732-9c1d-d737915e1fa7.gif)
