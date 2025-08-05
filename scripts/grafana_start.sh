#!/bin/bash

logdir="$HOME/tmp/monitoring"
dir="$HOME/Projects/monitoring"
grafana_dir=$dir/grafana

#grafana
$grafana_dir/bin/grafana-server --homepath $grafana_dir --packaging=brew cfg:default.paths.logs=$grafana_dir cfg:default.paths.data=$grafana_dir cfg:default.paths.plugins=$grafana_dir/plugins > $logdir/grafana.out 2>$logdir/grafana.err
