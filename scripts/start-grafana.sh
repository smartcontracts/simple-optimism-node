#!/bin/sh

if [ "$MONITORING_ENABLED" = "true" ]; then
  exec /run.sh
else
  echo "Grafana is disabled, exiting..."
  exit 0
fi
