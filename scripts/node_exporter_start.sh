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

LOG_DIR="${MONITORING_LOG_DIR:-$MONITORING_BASE_DIR/logs}"
NODE_EXPORTER_DIR="$MONITORING_BASE_DIR/node_exporter"

# Prepare log files
mkdir -p "$LOG_DIR"
touch "$LOG_DIR/node_exporter.out" "$LOG_DIR/node_exporter.err"

# Launch
"$NODE_EXPORTER_DIR/node_exporter" > "$LOG_DIR/node_exporter.out" 2> "$LOG_DIR/node_exporter.err"
echo "✅ node_exporter started from $NODE_EXPORTER_DIR/node_exporter"
