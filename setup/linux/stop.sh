#!/bin/bash

node_exporter=$(pidof node_exporter)
prometheus=$(pidof prometheus)

kill -9 $prometheus
kill -9 $node_exporter

sudo systemctl stop grafana-server
