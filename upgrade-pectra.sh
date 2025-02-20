#!/bin/bash
set -e  # Exit immediately if any command fails

echo "Shutting down current Docker Compose services..."
docker compose down

echo "Checking out branch 'pectra-upgrade-temp'..."
git checkout pectra-upgrade-temp

echo "Starting Docker Compose services with rebuild..."
docker compose up -d --build

echo "Creating upgrade flag file..."
mkdir -p .upgrade-pectra
touch ./.upgrade-pectra/upgraded

# Start the background pectra upgrade process
(
  echo "Background process started. Waiting 1 day before performing pectra upgrade..."
  sleep 86400  # Sleep for 1 day (86400 seconds)

  echo "Stopping Docker Compose services for pectra upgrade..."
  docker compose down

  echo "Checking out branch 'main'..."
  git checkout main

  echo "Starting Docker Compose services with rebuild on 'main' branch..."
  docker compose up -d --build

  echo "Pectra upgrade process complete."
) &

echo "Script execution complete. The pectra upgrade process is running in the background."
