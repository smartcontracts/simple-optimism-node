# Simple Optimism Node

A simple docker compose script for launching full / archive node for OP Stack chains.

<!-- ## Use cases

* Docker compose to launch Optimism mainnet full / archive node -->

## Recommended Hardware

- 16GB+ RAM
- 2TB SSD (NVME Recommended)
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

### Clone the Repository

```sh
git clone https://github.com/smartcontracts/simple-optimism-node.git
cd simple-optimism-node
```

### Copy .env.example to .env

Make a copy of `.env.example` named `.env`.

```sh
cp .env.example .env
```

Open `.env` with your editor of choice

### Mandatory configurations

* **NETWORK_NAME** - Choose which Optimism network layer you want to operate on:
    * `op-mainnet` - Optimism Mainnet
    * `op-sepolia` - Optimism Sepolia (Testnet)
* **NODE_TYPE** - Choose the type of node you want to run:
    * `full` (Full node) - A Full node contains a few recent blocks without historical states.
    * `archive` (Archive node) - An Archive node stores the complete history of the blockchain, including historical states.
* **OP_NODE__RPC_ENDPOINT** - Specify the endpoint for the RPC of Layer 1 (e.g., Ethereum mainnet). For instance, you can use the free plan of Alchemy for the Ethereum mainnet.
* **OP_NODE__RPC_TYPE** - Specify the service provider for the RPC endpoint you've chosen in the previous step. The available options are:
    * `alchemy` - Alchemy
    * `quicknode` - Quicknode (ETH only)
    * `erigon` - Erigon
    * `basic` - Other providers
* **HEALTHCHECK__REFERENCE_RPC_PROVIDER** - Specify the public RPC endpoint for Layer 2 network you want to operate on for healthchecking. For instance:
    * **Optimism Mainnet** - https://mainnet.optimism.io
    * **Optimism Sepolia** - https://sepolia.optimism.io

### OP Mainnet only configurations

* **OP_GETH__HISTORICAL_RPC** - OP Mainnet RPC Endpoint for fetching pre-bedrock historical data
    * **Recommended:** https://mainnet.optimism.io
    * Leave blank if you want to self-host pre-bedrock historical node for high-throughput use cases such as subgraph indexing.

### Optional configurations

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
* l2geth

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

```sh
docker compose pull
docker compose up -d --build --force-recreate
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

### Grafana dashboard

Grafana is exposed at [http://localhost:3000](http://localhost:3000) and comes with one pre-loaded dashboard ("Simple Node Dashboard").
Simple Node Dashboard includes basic node information and will tell you if your node ever falls out of sync with the reference L2 node or if a state root fault is detected.

Use the following login details to access the dashboard:

- Username: `admin`
- Password: `optimism`

Navigate over to `Dashboards > Manage > Simple Node Dashboard` to see the dashboard, see the following gif if you need help:

![metrics dashboard gif](https://user-images.githubusercontent.com/14298799/171476634-0cb84efd-adbf-4732-9c1d-d737915e1fa7.gif)
