# Simple Optimism Node

I think it's really important that people start running their own Optimism nodes.
I've created this repository to make that process as simple as possible.
You should be relatively familiar with running commands on your machine.
Let's do it!

## Required Software

- [Docker](https://docs.docker.com/get-docker/)

## Recommended Hardware

- 16GB+ RAM
- 500GB+ disk (HDD works for now, SSD is better)
- 10mb/s+ download

## Setting a Data Directory

Please note that this is an *optional* step but might be useful for anyone who was confused as I was about how to make Docker point at a different disk.
If you'd like your Docker data to live on a disk other than your primary disk, update or create `/etc/docker/daemon.json`:

```json
{
    "data-root": "/mnt/<disk>/docker_data"
}
```

## Environment Variables

Copy `.env.example` to `.env`. and fill out some environment variables.
Only the following required variables are required:

| Variable Name                           | Description                                                     |
|-----------------------------------------|-----------------------------------------------------------------|
| `NETWORK_NAME`                          | Network to run the node on ("mainnet" or "kovan")               |
| `HEALTHCHECK__REFERENCE_RPC_PROVIDER`   | Another reference L2 node to check blocks against, just in case |
| `FAULT_DETECTOR__L1_RPC_PROVIDER`       | L1 node RPC to check state roots against                        |
| `DATA_TRANSPORT_LAYER__L1_RPC_ENDPOINT` | L1 node RPC to download L2 blocks from                          |

## Running the Node

### Start

```sh
docker compose up -d
```

### View logs

```sh
docker compose logs [component name]
```

### Stop

```sh
docker compose down
```

### Wipe

```sh
docker compose down -v
```

## What's Included

### Optimism Node

Currently, an Optimism node can either sync from L1 or from other L2 nodes.
Syncing from L1 is generally the safest option but takes longer.
A node that syncs from L1 will also lag behind the tip of the chain depending on how long it takes for the Optimism Sequencer to publish transactions to Ethereum.
Syncing from L2 is faster but (currently) requires trusting the L2 node you're syncing from.

Many people are running nodes that sync from other L2 nodes, but I'd like to incentivize more people to run nodes that sync directly from L1.
As a result, I've set this repository up to sync from L1 by default.
I may later add the option to sync from L2 but I need to go do other things for a while.

#### Connecting to the Optimism Node




### Healthcheck + Fault Detector

When you run your Optimism node using these instructions, you will also be running two services that monitor the health of your node and the health of the network.
The Healthcheck service will constantly compare the state computed by your node to the state of some other reference node.
This is a great way to confirm that your node is syncing correctly.

The Fault Detector service will continuously scan the transaction results published by the Optimism Sequencer and cross-check them against the transaction results that your node generated locally.
If there's ever a discrepancy between these two values, please complain very loudly!
In the future, this service will trigger Cannon, the fault proving mechanism that Optimism is building as part of its Bedrock upgrade.

### Metrics Dashboard

Grafana is exposed at [http://localhost:3000](http://localhost:3000) and comes with one pre-loaded dashboard ("Simple Node Dashboard").
Simple Node Dashboard includes basic node information and will tell you if your node ever falls out of sync with the reference L2 node or if a state root fault is detected.

Use the following login details to access the dashboard:

* Username: `admin`
* Password: `optimism`

Navigate over to `Dashboards > Manage > Simple Node Dashboard` to see the dashboard, see the following gif if you need help:

![metrics dashboard gif](https://user-images.githubusercontent.com/14298799/171476634-0cb84efd-adbf-4732-9c1d-d737915e1fa7.gif)
