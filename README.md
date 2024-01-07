# Simple Optimism Node

I think it's really important that people start running their own Optimism nodes.
I've created this repository to make that process as simple as possible.
You should be relatively familiar with running commands on your machine.
Let's do it!

## Bedrock Support

`simple-optimism-node` now supports the Bedrock versions of both OP Mainnet and OP Goerli.
Please note that, for the moment, this repository *only* supports running a Bedrock node from the pre-migrated data directory supplied by OP Labs.
I am working on including the functionality for self-migration but I wanted to get something functional out there as quickly as possible.

Previous versions of this repository used a torrenting system for downloading configuration files and data directories.
I've decided to move to Cloudflare R2 temporarily since it provides better download speeds and is relatively inexpensive.
I will likely move back to a torrenting model in the future but R2 allows people to get running with Bedrock more quickly.

## Required Software

- [docker](https://docs.docker.com/engine/install/)

## Recommended Hardware

- 16GB+ RAM
- 2TB SSD
- 10mb/s+ download

## Installation and Setup Instructions

Instructions here should work for MacOS and most Linux distributions.
I probably won't include instructions for Windows because I'm lazy.

### Configure Docker as a Non-Root User (Optional)

If you're planning to run Docker as a root user, you can safely skip this step.
However, if you're using Docker as a non-root user, you'll need to add yourself to the `docker` user group:

```sh
sudo usermod -a -G docker `whoami`
```

You'll need to log out and log in again for this change to take effect.

### Clone the Repository

```sh
git clone https://github.com/smartcontracts/simple-optimism-node.git
cd simple-optimism-node
```

### Configure the Node

Make a copy of `.env.example` named `.env`.

```sh
cp .env.example .env
```

Open `.env` with your editor of choice and fill out the environment variables listed inside that file.
You MUST fill in all variables in the `REQUIRED (LEGACY)` OR `REQUIRED (BEDROCK)` sections.
If you wish to run both a legacy node and a Bedrock node at the same time, you MUST fill in BOTH sections.

You can also modify any of the optional environment variables if you'd wish, but the defaults should work perfectly well for most people.
You can get L1/L2 RPC endpoints from [these node providers](https://community.optimism.io/docs/useful-tools/providers/) or by running your own nodes.

#### Notes for Selected Variables

##### `OP_NODE__RPC_TYPE`

The `OP_NODE__RPC_TYPE` environment variable tells the `op-node` component of the Bedrock node what sort of RPC it is connected to.
When this variable is configured properly `op-node` can execute more efficiently by using special RPC endpoints that some RPC providers have and others may not.
The available options for this variable are `alchemy`, `quicknode`, `infura`, `parity`, `nethermind`, `debug_geth`, `erigon`, `basic`, and `any`.
The default is `basic`.

##### `OP_GETH__HISTORICAL_RPC`

Standard queries like `eth_getBlockByNumber` will execute properly for blocks before the Bedrock upgrade but `op-geth` is not able to execute the legacy state transition function.
This means that `op-geth` cannot natively serve requests like `eth_call` that require executing the legacy state transition.

The `OP_GETH__HISTORICAL_RPC` environment variable points `op-geth` to a node running the legacy version of OP Mainnet.
`op-geth` will use this to serve certain historical queries that can't be fulfilled by `op-geth` itself.
If this variable isn't defined, it defaults to attempting to use the legacy node spun up by this tool.
If you are not running a legacy node alongside `op-geth` and you do not supply this environment variable, your `op-geth` will not be able to serve these sort of legacy requests.

### Setting a Data Directory (Optional)

Please note that this is an *optional* step but might be useful for anyone who was confused as I was about how to make Docker point at disk other than your primary disk.
If you'd like your Docker data to live on a disk other than your primary disk, create a file `/etc/docker/daemon.json` with the following contents:

```json
{
    "data-root": "/mnt/<disk>/docker_data"
}
```

Make sure to restart docker after you do this or the changes won't apply:

```sh
sudo systemctl daemon-reload
sudo systemctl restart docker
```

Confirm that the changes were properly applied:

```sh
docker info | grep -i "Docker Root Dir"
```

### Operating the Node

#### Profiles

`simple-optimism-node` now supplies two [docker compose profiles](https://docs.docker.com/compose/profiles/) for the `current` system and the `legacy` system.
If you want to run BOTH of the systems in tandem, run the commands below WITHOUT the `--profile current` flag.

#### Start

```sh
docker compose --profile current up -d
```

Will start the node in a detatched shell (`-d`), meaning the node will continue to run in the background.
You will need to run this again if you ever turn your machine off.

#### Stop

```sh
docker compose --profile current down
```

Will shut down the node without wiping any volumes.
You can safely run this command and then restart the node again.

#### Wipe

```sh
docker compose --profile current down -v
```

Will completely wipe the node by removing the volumes that were created for each container.
Note that this is a destructive action, be very careful!

You may need to do this if the `op-geth` data directory becomes corrupted because of an unclean shutdown.
Your `op-geth` data directory is likely corrupted if you see the following error log from the `op-node`:

```
stage 0 failed resetting: temp: failed to find the L2 Heads to start from: failed to fetch L2 block by hash 0x0000000000000000000000000000000000000000000000000000000000000000
```

#### Logs

```sh
docker compose logs <service name>
```

Will display the logs for a given service.
You can also follow along with the logs for a service in real time by adding the flag `-f`.

The available services are:

- [`dtl`, `l2geth`, `op-node`, and `op-geth`](#optimism-node)
- [`healthcheck`](#healthcheck)
- [`fault-detector`](#fault-detector)
- [`prometheus`, `grafana`, and `influxdb`](#metrics-dashboard)

#### Update

```sh
docker compose pull
docker compose up --profile current -d --build
```

Will download the latest images for any services where you haven't hard-coded a service version.
Updates are regularly pushed to improve the stability of Optimism nodes or to introduce new quality-of-life features like better logging and better metrics.
I recommend that you run this command every once in a while (once a week should be more than enough).
If you intend to maintain an Optimism node for a long time, it's also worth tracking the [Monorepo's releases](https://github.com/ethereum-optimism/optimism/releases) to keep an eye on important changes.

## What's Included

### Optimism Node

Currently, an Optimism node can either sync from L1 or from other L2 nodes.
Syncing from L1 is generally the safest option but takes longer.
A node that syncs from L1 will also lag behind the tip of the chain depending on how long it takes for the Optimism Sequencer to publish transactions to Ethereum.
Syncing from L2 is faster but (currently) requires trusting the L2 node you're syncing from.

Many people are running nodes that sync from other L2 nodes, but I'd like to incentivize more people to run nodes that sync directly from L1.
As a result, I've set this repository up to sync from L1 by default.
I may later add the option to sync from L2 but I need to go do other things for a while.

### Healthcheck

When you run your Optimism node using these instructions, you will also be running two services that monitor the health of your node and the health of the network.
The Healthcheck service will constantly compare the state computed by your node to the state of some other reference node.
This is a great way to confirm that your node is syncing correctly.

### Fault Detector

The Fault Detector service will continuously scan the transaction results published by the Optimism Sequencer and cross-check them against the transaction results that your node generated locally.
**If there's ever a discrepancy between these two values, please complain very loudly!**
This either means that the Sequencer has published an invalid transaction result or there's a bug in your node software and an Optimism developer needs to know about it.
In the future, this service will trigger Cannon, the fault proving mechanism that Optimism is building as part of its Bedrock upgrade.

The Fault Detector exposes several metrics that can be used to determine whether your node has detected a discrepancy including the `is_currently_diverged` gauge. The Fault Detector also exposes a simple API at `localhost:$PORT__FAULT_DETECTOR_METRICS/api/status` which returns `{ ok: boolean }`. You can use this API to monitor the status of the Fault Detector from another application.

### Metrics Dashboard

Grafana is exposed at [http://localhost:3000](http://localhost:3000) and comes with one pre-loaded dashboard ("Simple Node Dashboard").
Simple Node Dashboard includes basic node information and will tell you if your node ever falls out of sync with the reference L2 node or if a state root fault is detected.

Use the following login details to access the dashboard:

- Username: `admin`
- Password: `optimism`

Navigate over to `Dashboards > Manage > Simple Node Dashboard` to see the dashboard, see the following gif if you need help:

![metrics dashboard gif](https://user-images.githubusercontent.com/14298799/171476634-0cb84efd-adbf-4732-9c1d-d737915e1fa7.gif)
