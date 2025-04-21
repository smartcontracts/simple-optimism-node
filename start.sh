#!/bin/bash

# Get the execution client from env var or default to op-geth
CLIENT=${EXECUTION_CLIENT:-op-geth}

# Map the client name to the correct profile
if [ "$CLIENT" = "nethermind" ]; then
    PROFILE="nethermind"
else
    PROFILE="op-geth"
fi

# Stop any running containers and remove volumes
docker compose down -v

# Start with the appropriate profile
docker compose --profile $PROFILE up -d --build
