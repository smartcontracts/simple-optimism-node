#!/bin/sh

if [ "$MONITORING_ENABLED" = "true" ]; then
  npm run start
else
  echo "Healthcheck is disabled, exiting..."
  exit 0
fi
