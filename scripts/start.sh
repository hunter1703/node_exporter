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

# Check required scripts exist
for component in node_exporter_start.sh prometheus_start.sh grafana_start.sh; do
    if [ ! -x "$MONITORING_BASE_DIR/scripts/$component" ]; then
        echo "❌ Missing or non-executable: $MONITORING_BASE_DIR/scripts/$component"
        exit 1
    fi
done

# Start components
"$MONITORING_BASE_DIR/scripts/node_exporter_start.sh" &
"$MONITORING_BASE_DIR/scripts/prometheus_start.sh" &
"$MONITORING_BASE_DIR/scripts/grafana_start.sh" &