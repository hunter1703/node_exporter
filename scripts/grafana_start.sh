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

# Locate Homebrew-installed grafana
GRAFANA_BIN="$(command -v grafana)"

if [ -z "$GRAFANA_BIN" ]; then
    echo "❌ grafana not found in PATH. Is Grafana installed via brew?"
    exit 1
fi
GRAFANA_DIR="$MONITORING_BASE_DIR/grafana"
GRAFANA_HOME=$(brew --prefix grafana)

"$GRAFANA_BIN" server --homepath=$GRAFANA_HOME/share/grafana cfg:default.paths.logs=$LOG_DIR > "$LOG_DIR/grafana.out" 2> "$LOG_DIR/grafana.err" &
