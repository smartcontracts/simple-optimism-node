# Simple Optimism Node

I think it's really important that people start running their own Optimism nodes.
I've created this repository to make that process as simple as possible.
You should be relatively familiar with running commands on your machine.
Let's do it!

## Bedrock Support

The Optimism Goerli testnet was upgraded to Bedrock on Thursday January 12th 2023.
I am in the process of working on full Bedrock support within `simple-optimism-node`.
You can run a Goerli Bedrock node with some limitations as described in the [Bedrock Limitations](#bedrock-limitations) section below.
Please read those limitations carefully, they'll be updated and removed as I work on additional features.

Please also report any bugs that you find, it'll help speed up the process of getting to production Goerli Bedrock nodes.
Thank you!

### Bedrock Limitations

- No upload limits for BitTorrent yet.
- No functional metrics dashboard.
- No fault detector.

## Required Software

- [docker](https://docs.docker.com/engine/install/)

## Recommended Hardware

- 16GB+ RAM
- 500GB+ disk (HDD works for now, SSD is better)
- 10mb/s+ download

## Approximate Disk Usage

Usage as of 2022-09-21:

- Archive node: ~800gb
- Full node: ~60gb

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

### Open the BitTorrent port

BitTorrent is a system used to share files over a p2p network.
`simple-optimism-node` uses BitTorrent to download certain important files in a decentralized manner.
Although BitTorrent may have a negative connotation due to its occasional use in sharing copyrighted files, all of the files that `simple-optimism-node` shares and downloads via BitTorrent are entirely legal configuration files for the system.

For `simple-optimism-node` to operate properly, you will need to open the port that our BitTorrent client, `qBitTorrent`, uses.
By default, this port is 6881 (you may need to run the following command as root):

```sh
ufw allow 6881
```

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
You MUST fill in all variables in the `REQUIRED` section.
Currently, this repository is only configured to run both a legacy node and a Bedrock node (if the network has been upgraded to Bedrock), so you MUST fill in both `REQUIRED (LEGACY)` and `REQUIRED (BEDROCK)`.
You can also modify any of the optional environment variables if you'd wish, but the defaults should work perfectly well for most people.
You can get L1/L2 RPC endpoints from [these node providers](https://community.optimism.io/docs/useful-tools/providers/) or by running your own nodes.

#### Setting a qBittorrent UI password

If you are running a Bedrock node, you will be running a torrent client for downloading certain important files.
The default qBittorrent password is `adminadmin`.
It is HIGHLY recommended that you change this password to avoid compromise.
You can change the password by heading over to the qBittorrent UI (located on localhost:8080), opening up preferences, then "Web UI", and setting your custom password.

#### Notes for Selected Variables

##### `SYNC_SOURCE`

The `SYNC_SOURCE` environment variable tells legacy nodes where to sync data from and can have a value of either `l1` or `l2`.
It is recommended to sync from `l1` because `l1` sync is entirely trustless, whereas `l2` sync requires trusting the `l2` node you are syncing from.
However, `l2` sync is keeps your node closer to the tip of the L2 chain.
Note that this only applies to legacy nodes, not Bedrock nodes.
After the Bedrock transition, the `l2` sync option will be removed.

##### `BEDROCK_SOURCE`

The `BEDROCK_SOURCE` environment variable determines where Bedrock nodes will get the database that it needs to start syncing and can have a value of either `download` or `migration`.

When getting the database via `download`, the node will fetch the database over BitTorrent.
This is recommended for anyone starting a fresh node that only needs to keep up with the Bedrock network.

When getting the database via `migration`, the node will look for an existing legacy database and migrate a copy of this database trustlessly to Bedrock.
This is recommended for anyone who already runs a legacy node with `simple-optimism-node` and wants the most trustless way to execute and verify the Bedrock upgrade.
Note that you MUST have a fully synced legacy node for this option to work.

##### `OP_NODE__RPC_TYPE`

The `OP_NODE__RPC_TYPE` envrionemnt variable tells the `op-node` component of the Bedrock node what sort of RPC it is connected to.
When this variable is configured properly `op-node` can execute more efficiently by using special RPC endpoints that some RPC providers have and others may not.
The available options for this variable are `alchemy`, `quicknode`, `infura`, `parity`, `nethermind`, `debug_geth`, `erigon`, `basic`, and `any`.
The default is `basic`.

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

#### Start

```sh
docker compose up -d
```

Will start the node in a detatched shell (`-d`), meaning the node will continue to run in the background.
You will need to run this again if you ever turn your machine off.

The first time you start the node it synchronizes from regenesis (November 11th, 2021) to the present.
This process takes hours.

#### Stop

```sh
docker compose down
```

Will shut down the node without wiping any volumes.
You can safely run this command and then restart the node again.

#### Wipe

```sh
docker compose down -v
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

- [`dtl` and `l2geth`](#optimism-node)
- [`healthcheck`](#healthcheck)
- [`fault-detector`](#fault-detector)
- [`prometheus`, `grafana`, and `influxdb`](#metrics-dashboard)

#### Update

```sh
docker compose pull
```

Will download the latest images for any services where you haven't hard-coded a service version.
Updates are regularly pushed to improve the stability of Optimism nodes or to introduce new quality-of-life features like better logging and better metrics.
I recommend that you run this command every once in a while (once a week should be more than enough).
If you intend to maintain an Optimism node for a long time, it's also worth subscribing to the [Optimism Public Changelog](https://changelog.optimism.io/) via either [RSS](https://changelog.optimism.io/feed.xml) or the [optimism-announce@optimism.io mailing list](https://groups.google.com/a/optimism.io/g/optimism-announce).

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

