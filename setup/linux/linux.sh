#!/bin/bash

#node_exporter
~/Documents/node_exporter/node_exporter 2>&1 &

#prometheus
~/Documents/prometheus-2.28.1.darwin-amd64/prometheus --config.file=~/Documents/prometheus-2.28.1.darwin-amd64/prometheus.yml 2>&1 &

#grafana
grafana-server --config=/usr/local/etc/grafana/grafana.ini --homepath /usr/local/share/grafana --packaging=brew cfg:default.paths.logs=/usr/local/var/log/grafana cfg:default.paths.data=/usr/local/var/lib/grafana cfg:default.paths.plugins=/usr/local/var/lib/grafana/plugins 2>&1 &
