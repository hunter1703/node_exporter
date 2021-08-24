#!/bin/bash

node_exporter=$(pidof node_exporter)
prometheus=$(pidof prometheus)
grafana=$(pidof grafana-server)

kill -9 $prometheus
kill -9 $node_exporter
kill -9 $grafana
