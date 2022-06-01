# Simple Optimism Node

I think it's really important that people start running their own Optimism nodes.
I've created this repository to make that process as simple as possible.
You should be relatively familiar with running commands on your machine.
Let's do it!

## Required Software

- [Docker](https://docs.docker.com/get-docker/)
- [Docker Compose](https://docs.docker.com/compose/install/) (comes bundled with Docker Desktop)

## Recommended Hardware

- 16GB+ RAM
- 500GB+ disk (HDD works for now, SSD is better)
- 10mb/s+ download

## Setting a Data Directory

If you'd like your Docker data to live on a disk other than your primary disk, update or create `/etc/docker/daemon.json` with the following:

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

## Metrics Dashboard

Grafana is exposed at [http://localhost:3000](http://localhost:3000) and comes with one pre-loaded dashboard ("Simple Node Dashboard").
Simple Node Dashboard includes basic node information and will tell you if your node ever falls out of sync with the reference L2 node or if a state root fault is detected.

Use the following login details to access the dashboard:

* Username: `admin`
* Password: `optimism`

Navigate over to `Dashboards > Manage > Simple Node Dashboard` to see the dashboard, see the following gif if you need help:

![metrics dashboard gif](https://user-images.githubusercontent.com/14298799/171476634-0cb84efd-adbf-4732-9c1d-d737915e1fa7.gif)