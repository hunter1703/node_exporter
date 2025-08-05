#!/bin/bash

logdir="$HOME/tmp/monitoring"
dir="$HOME/Projects/monitoring"
prometheus_dir=$dir/prometheus

# create folders and files
mkdir -p $logdir
touch $logdir/prometheus.out
touch $logdir/prometheus.err

$prometheus_dir/prometheus --storage.tsdb.path=$prometheus_dir/data --config.file=$prometheus_dir/prometheus.yml > $logdir/prometheus.out 2>$logdir/prometheus.err
