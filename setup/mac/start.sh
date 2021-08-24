#!/bin/bash

logdir="/Users/gandalf/Projects/tmp/monitoring"
dir="/Users/gandalf/Projects/monitoring"
node_exporter_dir=$dir/node_exporter
prometheus_dir=$dir/prometheus
grafana_dir=$dir/grafana

# create folders and files
mkdir -p $logdir
touch $logdir/node_exporter.out
touch $logdir/node_exporter.err
touch $logdir/prometheus.out
touch $logdir/prometheus.err
#node_exporter
$node_exporter_dir/node_exporter > $logdir/node_exporter.out 2>$logdir/node_exporter.err &

#prometheus
$prometheus_dir/prometheus --config.file=$prometheus_dir/prometheus.yml > $logdir/prometheus.out 2>$logdir/prometheus.err &

#grafana
$grafana_dir/bin/grafana-server --homepath $grafana_dir --packaging=brew cfg:default.paths.logs=$grafana_dir cfg:default.paths.data=$grafana_dir cfg:default.paths.plugins=$grafana_dir/plugins > $logdir/grafana.out 2>$logdir/grafana.err &
