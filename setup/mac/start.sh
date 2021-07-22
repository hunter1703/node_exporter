#!/bin/bash

dir="~/monitoring"
mkdir -p $dir
#node_exporter
/Users/rahul/Downloads/node_exporter/node_exporter > $dir/node_exporter.out 2>$dir/node_exporter.err &

#prometheus
/Users/rahul/Downloads/prometheus-2.27.1.darwin-amd64/prometheus --config.file=/Users/rahul/Downloads/prometheus-2.27.1.darwin-amd64/prometheus.yml > $dir/prometheus.out 2>$dir/prometheus.err &

#grafana
grafana-server --config=/usr/local/etc/grafana/grafana.ini --homepath /usr/local/share/grafana --packaging=brew cfg:default.paths.logs=/usr/local/var/log/grafana cfg:default.paths.data=/usr/local/var/lib/grafana cfg:default.paths.plugins=/usr/local/var/lib/grafana/plugins > $dir/grafana.out 2>$dir/grafana.err &
