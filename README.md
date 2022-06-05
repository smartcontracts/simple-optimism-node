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

### Stop

```sh
docker compose down
```

### Wipe

```sh
docker compose down -v
```

### Logs

```sh
docker compose logs <service name (see docker-compose.yml)>
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

## Detailed Instructions

These instructions assume a debian linux platform, but aside from the package installation, this translates fairly directly.

### Installation

Start by pulling down the repo.  Open a terminal and navigate to where you want the new folder created.  Run the following:

```sh
git clone https://github.com/smartcontracts/simple-optimism-node.git
```

You should see something like this:

![git clone output image](https://user-images.githubusercontent.com/94415863/171551614-4c1b61e7-40f6-4649-a163-b2ffb24fa632.png)

### Configuring

Change into the new directory:

```sh
cd simple-optimism-node
```

There is a hidden file called `.env.example`. We want to copy it to `.env`.

 ```sh
cp .env.example .env
```
![cd list copy image](https://user-images.githubusercontent.com/94415863/171552299-ecacfeca-0fd1-40a4-8fc0-68e419a9c577.png)


And then edit it with your editor of choice

```sh
nano .env
```
The file has a few variables in it we need to fill.

![empty env](https://user-images.githubusercontent.com/94415863/171552497-9727dc0d-1376-4319-8b75-5a687f4adf12.png)


To do that, we need to get an L1 and an L2 RPC endpoint. You can use any you want, Alchemy, Infura, Quicknode, etc.  Free tier is fine on Alchemy.

![alchemy rpcs](https://user-images.githubusercontent.com/94415863/171552658-e461eb8f-2ac3-4b24-a61f-0c464f9c4a93.png)

View and Copy the keys, and paste them into `.env`:

![rpc examples](https://user-images.githubusercontent.com/94415863/171552935-66944e35-e72c-449a-b162-dd78221fddb9.png)

To speed up syncing, we're also going to update `IMAGE_TAG__L2GETH`.  This is a temporary measure until a specific ticket is merged.

```sh
prerelease-0.0.0-test-parallel-sync-2
```
![l2geth temp tag](https://user-images.githubusercontent.com/94415863/171553128-dcf1821f-1a10-4249-a099-0873f61f7e02.png)

At this point, you can use the docker commands to pull down the images and run them.  You image may look different while it pulls everything down.

```sh
docker compose up -d
```

![image](https://user-images.githubusercontent.com/94415863/171553460-837c3763-24e5-4025-a1af-d06415771beb.png)

And you can hop over to the graphana dashboard to see it start to sync up.

[http://localhost:3000/dashboards](http://localhost:3000/dashboards)

On my current system, I've estimated syncing will take about 60hours.  We'll see if that's how it plays out.  Congrats on running your own Optimism Node!

=======
