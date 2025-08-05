#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_PATH="$SCRIPT_DIR/../.env"

if [ -f "$ENV_PATH" ]; then
    # shellcheck disable=SC1090
    source "$ENV_PATH"
else
    echo "❌ .env not found at $ENV_PATH. Please run setup.sh first."
    exit 1
fi

# Define paths
LOG_DIR="${MONITORING_LOG_DIR:-$MONITORING_BASE_DIR/logs}"
PROMETHEUS_DIR="$MONITORING_BASE_DIR/prometheus"
PROMETHEUS_BIN="$PROMETHEUS_DIR/prometheus"
PROMETHEUS_YML="$PROMETHEUS_DIR/prometheus.yml"
PROMETHEUS_DATA="$PROMETHEUS_DIR/data"

# Check for binary and config
if [ ! -x "$PROMETHEUS_BIN" ]; then
    echo "❌ prometheus binary not found or not executable at: $PROMETHEUS_BIN"
    exit 1
fi
if [ ! -f "$PROMETHEUS_YML" ]; then
    echo "❌ Missing Prometheus config file: $PROMETHEUS_YML"
    exit 1
fi

# Prepare log files
mkdir -p "$LOG_DIR"
touch "$LOG_DIR/prometheus.out" "$LOG_DIR/prometheus.err"

# Launch Prometheus
"$PROMETHEUS_BIN" \
  --storage.tsdb.path="$PROMETHEUS_DATA" \
  --config.file="$PROMETHEUS_YML" \
  > "$LOG_DIR/prometheus.out" 2> "$LOG_DIR/prometheus.err" &

echo "✅ prometheus started from $PROMETHEUS_BIN"
