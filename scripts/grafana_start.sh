#!/bin/bash

# Resolve script dir and load .env
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_PATH="$SCRIPT_DIR/../.env"

if [ -f "$ENV_PATH" ]; then
    # shellcheck disable=SC1090
    source "$ENV_PATH"
else
    echo "❌ .env not found at $ENV_PATH. Please run setup.sh first."
    exit 1
fi

# Get log dir
LOG_DIR="${MONITORING_LOG_DIR:-$MONITORING_BASE_DIR/logs}"
mkdir -p "$LOG_DIR"
touch "$LOG_DIR/grafana.out" "$LOG_DIR/grafana.err"

# Locate Homebrew-installed grafana-server
GRAFANA_BIN="$(command -v grafana-server)"

if [ -z "$GRAFANA_BIN" ]; then
    echo "❌ grafana-server not found in PATH. Is Grafana installed via brew?"
    exit 1
fi

# Launch Grafana (will use Homebrew config, data, logs)
"$GRAFANA_BIN" > "$LOG_DIR/grafana.out" 2> "$LOG_DIR/grafana.err" &

echo "✅ Grafana started from $GRAFANA_BIN (brew installation)"
