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

## L1 Data Migration

If you have been running an existing L1 node and wish to continue using the same datadir,
you can migrate the data in order to use it with the L2 node.

Also note that a migrated datadir is a pre-requisite for:
* Full syncing (as opposed to snap syncing).
* Having an archive node with all the states.

If you do not have an existing L1 datadir but wish to full sync and/or run an archive node with all
the states you will be able to download a migrated datadir hosted by cLabs.

### Running migration

A pre-migration option is provided to allow the bulk of the migration to occur
before the network migration point, thus allowing for minimal downtime at the
migration point.

Once the L1 network has reached the final block a full migration should be performed. It is envisaged that
pre-migrations will be run in the days leading up to the migration point, there is no limit to the number
of times pre-migration can be run.

Use the following commands to pre migrate and full migrate the data:

```sh
./migrate.sh pre <network> <source_L1_chaindata_dir> [dest_L2_chaindata_dir2]
./migrate.sh full <network> <source_L1_chaindata_dir> [dest_L2_chaindata_dir2]
```

If the destination dir is omitted `./envs/<network>/datadir` will be used.

## Starting the node

### Copy network env to .env

Copy the desired network environment file to `.env`.

E.g. to run a node on Alfajores:

```sh
cp alfajores.env .env
```
The `.env` file is ready to use and is configured for snap sync and non-archive mode. If you would like to customise
your node further see [Optional configurations](#optional-configurations).

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

### Estimate remaining sync time

Run progress.sh to estimate remaining sync time and speed.

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
