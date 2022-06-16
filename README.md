# Simple Optimism Node

I think it's really important that people start running their own Optimism nodes.
I've created this repository to make that process as simple as possible.
You should be relatively familiar with running commands on your machine.
Let's do it!

## Required Software

- [Docker](https://docs.docker.com/engine/install/)

  **Note:** To use Docker as a non root user, add that user to the `docker` group.

  ```
  sudo usermod -a -G docker `whoami`
  ```

  You'll need to log out and log in again for the change to be effective.

## Recommended Hardware

- 16GB+ RAM
- 500GB+ disk (HDD works for now, SSD is better)
- 10mb/s+ download

## Installation and Setup Instructions

Instructions here should work for MacOS and most linux distributions.
I probably won't include instructions for Windows because I'm lazy.

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
Only the following required variables are required:

| Variable Name                           | Description                                                     |
|-----------------------------------------|-----------------------------------------------------------------|
| `NETWORK_NAME`                          | Network to run the node on ("mainnet" or "kovan")               |
| `HEALTHCHECK__REFERENCE_RPC_PROVIDER`   | Another reference L2 node to check blocks against, just in case |
| `FAULT_DETECTOR__L1_RPC_PROVIDER`       | L1 node RPC to check state roots against                        |
| `DATA_TRANSPORT_LAYER__L1_RPC_ENDPOINT` | L1 node RPC to download L2 blocks from                          |

You can get L1/L2 RPC endpoints from [these node providers](https://community.optimism.io/docs/useful-tools/providers/).

You can also modify any of the optional environment variables if you'd wish, but the defaults should work perfectly well for most people.
Just make sure not to change anything under the line marked "NO TOUCHING" or you might break something!

### Setting a Data Directory (Optional)

Please note that this is an *optional* step but might be useful for anyone who was confused as I was about how to make Docker point at disk other than your primary disk.
If you'd like your Docker data to live on a disk other than your primary disk, create a file `/etc/docker/daemon.json` with the following contents:

```json
{
    "data-root": "/mnt/<disk>/docker_data"
}
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

#### Logs

```sh
docker compose logs <service name>
```

Will display the logs for a given service.
You can also follow along with the logs for a service in real time by adding the flag `-f`.

The available services are:
- [`dtl` and `l2geth`](#optimism-node)
- [`healthcheck` and `fault-detector`](#healthcheck--fault-detector)
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
