#!/bin/bash

dir="/tmp/monitoring"
mkdir -p $dir
#node_exporter
~/Documents/node_exporter/node_exporter > $dir/node_exporter.out 2>$dir/node_exporter.err &

#prometheus
~/Documents/prometheus-2.27.1.linux-amd64/prometheus --config.file=/home/rahul/Documents/prometheus-2.27.1.linux-amd64/prometheus.yml > $dir/prometheus.out 2>$dir/prometheus.err &

#grafana
sudo systemctl restart grafana-server
