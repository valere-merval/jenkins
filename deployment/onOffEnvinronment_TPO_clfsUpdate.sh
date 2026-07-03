#!/bin/bash
set -e
action=$1
psxEnv=$2

cd ../update-stack
sed -i -e "s/Name:.*/Name: tpo-psx${psxEnv}-appsrv/g" \
-e "s/AsgSize:.*/AsgSize: ${action}/g" tpo-psx-onoff.cfg && \
cat tpo-psx-onoff.cfg && ./update-stack.py tpo-psx-onoff.cfg