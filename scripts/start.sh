#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_PATH="$SCRIPT_DIR/../.env"

# Load .env
if [ -f "$ENV_PATH" ]; then
    # shellcheck disable=SC1090
    source "$ENV_PATH"
else
    echo "❌ .env not found at $ENV_PATH. Please run setup.sh first."
    exit 1
fi

# Check required scripts
for component in node_exporter_start.sh prometheus_start.sh grafana_start.sh; do
    if [ ! -x "$MONITORING_BASE_DIR/scripts/$component" ]; then
        echo "❌ Missing or non-executable: $MONITORING_BASE_DIR/scripts/$component"
        exit 1
    fi
done

# Function to launch and validate a service
launch_component() {
    local name=$1
    local script=$2
    local port=$3   # Optional: for port-based check

    echo "🚀 Starting $name..."
    "$script" &
    local pid=$!

    # Check if process is alive
    if ps -p $pid > /dev/null; then
        echo "✅ $name started (PID $pid)"
        return 0
    else
        echo "❌ $name failed to start."
        return 1
    fi
}

# Launch in dependency order
launch_component "node_exporter" "$MONITORING_BASE_DIR/scripts/node_exporter_start.sh" || exit 1
launch_component "prometheus" "$MONITORING_BASE_DIR/scripts/prometheus_start.sh" || exit 1
launch_component "grafana" "$MONITORING_BASE_DIR/scripts/grafana_start.sh" || exit 1

echo "🎉 All monitoring services launched successfully."
