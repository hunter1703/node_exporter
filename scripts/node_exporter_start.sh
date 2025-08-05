#!/bin/bash

logdir="$HOME/tmp/monitoring"
dir="$HOME/Projects/monitoring"
node_exporter_dir=$dir/node_exporter

# create folders and files
mkdir -p $logdir
touch $logdir/node_exporter.out
touch $logdir/node_exporter.err

$node_exporter_dir/node_exporter > $logdir/node_exporter.out 2>$logdir/node_exporter.err
