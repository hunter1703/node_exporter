#!/bin/bash

$HOME/Projects/monitoring/scripts/node_exporter_start.sh &
$HOME/Projects/monitoring/scripts/prometheus_start.sh &
$HOME/Projects/monitoring/scripts/grafana_start.sh &