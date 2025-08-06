#!/bin/bash

components=("node_exporter" "prometheus" "grafana-server")

for name in "${components[@]}"; do
  pids=$(pgrep -f "$name")
  if [ -n "$pids" ]; then
    echo "🛑 Stopping $name..."
    kill $pids 2>/dev/null
    sleep 1
    if pgrep -f "$name" >/dev/null; then
      echo "⚠️  $name is still running — sending SIGKILL..."
      kill -9 $pids
    else
      echo "✅ $name stopped successfully."
    fi
  else
    echo "ℹ️  $name is not running."
  fi
done
