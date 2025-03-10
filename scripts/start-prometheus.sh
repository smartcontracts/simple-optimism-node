#!/bin/sh

if [ "$MONITORING_ENABLED" = "true" ]; then
  exec /bin/prometheus \
    --config.file=/etc/prometheus/prometheus.yml \
    --storage.tsdb.path=/prometheus
else
  echo "Prometheus is disabled, exiting..."
  exit 0
fi
