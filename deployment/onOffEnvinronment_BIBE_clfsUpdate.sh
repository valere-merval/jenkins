#!/bin/bash
set -e
action=$1
psxEnv=$2

cd ../update-stack
sed -i -e "s/Name:.*/Name: nvs-psx${psxEnv}-bibe/g" \
-e "s/NvsBibeAutoScalingDesiredCapacity:.*/NvsBibeAutoScalingDesiredCapacity: ${action}/g" \
-e "s/NvsBibeAutoScalingMaxSize:.*/NvsBibeAutoScalingMaxSize: ${action}/g" \
-e "s/NvsBibeAutoScalingMinSize:.*/NvsBibeAutoScalingMinSize: ${action}/g" nvs-psx-bibe-onoff.cfg && \
cat nvs-psx-bibe-onoff.cfg && ./update-stack.py nvs-psx-bibe-onoff.cfg
