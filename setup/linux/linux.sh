#!/bin/bash

#node_exporter
~/Documents/node_exporter/node_exporter 2>&1 &

#prometheus
~/Documents/prometheus-2.27.1.linux-amd64/prometheus --config.file=/home/rahul/Documents/prometheus-2.27.1.linux-amd64/prometheus.yml 2>&1 &

#grafana
sudo service grafana-server start
