# Docker Compose Setup for Running a Celo L2 Node

A simple docker compose script for launching Celo L2 full nodes.

<!-- ## Use cases
* Docker compose to launch Optimism mainnet full / archive node -->

## Recommended Hardware

### Testnets

- 16GB+ RAM
- 500 GB SSD (NVME Recommended)
- 100mb/s+ Download

## Installation and Configuration

### Install docker and docker compose

> Note: If you're not logged in as root, you'll need to log out and log in again after installation to complete the docker installation.

Note: This command install docker and docker compose for Ubuntu. For windows and mac desktop or laptop, please use Docker Desktop. For other OS, please find instruction in Google.

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

(For non-root user) After logged out and logged back in, test if docker is working by running.

```sh
docker ps
```

It should returns an empty container list without having any error. Otherwise, restart your machine if there are errors.

### MacOS configure virtual disk limit

If using Docker Desktop on MacOS you may need to increase the virtual disk
limit since the default size will likely not be enough to hold the chaindata
for any chains that have been operating for a while. This can be done by
opening Docker Desktop, going to Settings -> Resources -> Advanced and
increasing the disk image size.

### Clone the Repository

```sh
git clone https://github.com/celo-org/celo-l2-node-docker-compose.git
cd celo-l2-node-docker-compose
```

## Configuring a node

Example config is provided for Alfajores, Baklava and Mainnet (or will be
provided once the L2 versions of those networks are launched).

Copy the desired network environment file to `.env` (`.env` is used by
docker-compose to load environment variables).

E.g. to run a node on Alfajores:

```sh
cp alfajores.env .env
```
The `.env` file is ready to use and is configured for snap sync and non-archive mode. If you would like to customise
your node further see below.

### Node configurations

There are some choices that significantly affect how nodes need to be run. The
requirements for each are given below.

* Snap sync node:
  * No extra requirements, simply use the provided config.
* Full sync node:
   * A datadir migrated from an L1 node (this does not need to be an archive datadir)
   * Full sync configured
   * Example config adjustments:
     * ```
       OP_GETH__SYNCMODE=full
       DATADIR_PATH=<path to your migrated datadir>
       ```
* Historical archive access (historical execution and state access, e.g.
  `eth_call`, `eth_getBalance` ... etc for pre-L2 blocks)
   * Requires access to an L1 archive node, this can be achieved in one of 3 ways:
     * An existing L1 archive node datadir can be configured and an L1 node
       will be launched using that datadir
     * An empty datadir can be configured and an L1 archive node will be launched
       and sync using that datadir. Note that it will be some time till the L1
       node will be able to serve state queries
     * An L1 archive node URL can be configured
   * Example config adjustments:
     * ```
       HISTORICAL_RPC_DATADIR_PATH=<path to datadir> or OP_GETH__HISTORICAL_RPC=<historical rpc node endpoint>
       ```
* Full archive node with all states from genesis stored:
   * A datadir migrated from an L1 node (this does not need to be an archive datadir)
   * Full sync configured
   * Historical archive access configured (see above)
   * Example config adjustments:
     * ```
       OP_GETH__SYNCMODE=full
       DATADIR_PATH=<path to your migrated datadir>
       HISTORICAL_RPC_DATADIR_PATH=<path to datadir> or OP_GETH__HISTORICAL_RPC=<historical rpc node endpoint>
       ```

See [Obtaining a migrated L1 datadir](#obtaining-a-migrated-l1-datadir) for
instructions on obtaining a migrated L1 datadir.

### Optional configurations

* **NODE_TYPE** - Choose the type of node you want to run:
    * `full` (Full node) - A Full node contains a few recent blocks without historical states.
    * `archive` (Archive node) - An Archive node stores the complete history of the blockchain, including historical states.
* **OP_NODE__RPC_ENDPOINT** - Specify the endpoint for the RPC of Layer 1 (e.g., Ethereum mainnet). For instance, you can use the free plan of Alchemy for the Ethereum mainnet.
* **OP_NODE__L1_BEACON** - Specify the beacon endpoint of Layer 1. You can use [QuickNode for the beacon endpoint](https://www.quicknode.com). For example: https://xxx-xxx-xxx.quiknode.pro/db55a3908ba7e4e5756319ffd71ec270b09a7dce
* **OP_NODE__RPC_TYPE** - Specify the service provider for the RPC endpoint you've chosen in the previous step. The available options are:
    * `alchemy` - Alchemy
    * `quicknode` - Quicknode (ETH only)
    * `erigon` - Erigon
    * `basic` - Other providers
* **HEALTHCHECK__REFERENCE_RPC_PROVIDER** - Specify the public RPC endpoint for Layer 2 network you want to operate on for healthchecking.
* **HISTORICAL_RPC_DATADIR_PATH** - Datadir path to use for historical RPC node to serve pre-L2 historical state.
* **OP_GETH__HISTORICAL_RPC** - RPC Endpoint for fetching pre-L2 historical state, if set overrides the **HISTORICAL_RPC_DATADIR_PATH** setting.
    * Leave blank if you want to self-host pre-bedrock historical node for high-throughput use cases such as subgraph indexing.
* **IMAGE_TAG__[...]** - Use custom docker image for specified components.
* **PORT__[...]** - Use custom port for specified components.

## Obtaining a migrated L1 datadir

For some node configurations a migrated L1 datadir is required, you can obtain
one by following one of the options outlined below.

### 1. Download a pre-migrated datadir

If you do not have an existing L1 datadir but wish to full sync and/or run an
archive node you can download a migrated datadir hosted by cLabs from one of the links below.

* [Alfajores migrated datadir](https://storage.googleapis.com/cel2-rollup-files/alfajores/alfajores-migrated-datadir.tar.zst)
* Baklava migrated datadir - pending network launch
* Mainnet migrated datadir - pending network launch

### 2. Migrate your own datadir

If you have been running an existing L1 node and wish to continue using the same datadir,
you can migrate the data in order to use it with the L2 node.

Once an L2 hardfork date has been decided for a specific network the L1
[blockchain client](https://github.com/celo-org/celo-blockchain) will be
released with a hardcoded stop block. Nodes running this version will stop
producing blocks at the stop block, at which point the node can be shut down
and the datadir can be migrated.

Note that the migration does not modify the source datadir.

Run the migration with the following command, where network is one of(mainnet, alfajores or baklava):

```sh
./migrate.sh full <network> <source_L1_chaindata_dir> [dest_L2_chaindata_dir2]
```

If the destination dir is omitted `./envs/<network>/datadir` will be used.

#### Pre-migrations

In the case that you wish to suffer minimal downtime at the L2 hardfork point
you can run a pre-migration which will allow the bulk of a migration to occur
before the hardfork point, thus speeding up the final full migration.

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

```sh
docker compose logs -f --tail 10
```

To view logs of all containers.

```sh
docker compose logs <CONTAINER_NAME> -f --tail 10
```

To view logs for a specific container. Most commonly used `<CONTAINER_NAME>` are:
* op-geth
* op-node
* bedrock-init

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

Install foundry following the instructions of
<https://book.getfoundry.sh/getting-started/installation>

And then run progress.sh to estimate remaining sync time and speed.

```sh
./progress.sh
```

This will show the sync speed in blocks per minute and the time until sync is completed.

```
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

# Appendix

## L2 network assets

These assets are fetched when required by the scripts in this repo and so
should not need to be manually retrieved, however for completeness they are
provided here.

* Mainnet
 * Pending launch
* Alfajores - L2 fork block 26384000
  * [Full migrated chaindata](https://storage.googleapis.com/cel2-rollup-files/alfajores/alfajores-migrated-datadir.tar.zst)
  * [Rollup deploy config](https://storage.googleapis.com/cel2-rollup-files/alfajores/config.json)
  * [L1 contract addresses](https://storage.googleapis.com/cel2-rollup-files/alfajores/deployment-l1.json)
  * [L2 allocs](https://storage.googleapis.com/cel2-rollup-files/alfajores/l2-allocs.json)
  * [rollup.json](https://storage.googleapis.com/cel2-rollup-files/alfajores/rollup.json)
  * [Genesis](https://storage.googleapis.com/cel2-rollup-files/alfajores/genesis.json) used for snap syncing
* Baklava
 * Pending launch
