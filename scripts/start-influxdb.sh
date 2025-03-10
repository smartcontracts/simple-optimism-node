#!/bin/sh

if [ "$MONITORING_ENABLED" = "true" ]; then
  /entrypoint.sh influxd
else
  echo "Influxdb is disabled, exiting..."
  exit 0
fi
