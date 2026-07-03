#!/bin/bash
set -e

BIBE_IM=$1
psxEnv=$2

if [ -z ${PSX_HDM_LOCAL+x} ]; then
IP_PSX_HDM=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=nvs-psx-hdm" --query 'Reservations[*].Instances[*].PrivateIpAddress' --output text)
ssh ansible@$IP_PSX_HDM "mkdir -p ~/deployment ~/update-stack"
scp -rp BIBE_deploy_LatestAMI.sh ansible@$IP_PSX_HDM:~/deployment/BIBE_deploy_LatestAMI.sh
scp -rp ../update-stack/update-stack.py ansible@$IP_PSX_HDM:~/update-stack/update-stack.py
scp -rp ../update-stack/nvs-psx-bibe.cfg ansible@$IP_PSX_HDM:~/update-stack/nvs-psx-bibe.cfg
ssh -tt ansible@$IP_PSX_HDM '/bin/sh -c '"'"'echo BECOME-SUCCESS- auf $(uname -n); \
aws configure set region eu-central-1 && cd deployment && ./BIBE_deploy_LatestAMI.sh '${BIBE_IM}' '${psxEnv}' '"'"''
else
  ./BIBE_deploy_LatestAMI.sh "${BIBE_IM}" ${psxEnv}
fi