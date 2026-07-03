#!/bin/bash
set -e
psxEnv=$1


if [ -z ${PSX_HDM_LOCAL+x} ]; then
  IP_PSX_HDM=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=nvs-psx-hdm" --query 'Reservations[*].Instances[*].PrivateIpAddress' --output text)
  ssh ansible@$IP_PSX_HDM "mkdir -p ~/psx ~/update-stack"
  scp -rp TPO_deploy_LatestBI.sh ansible@$IP_PSX_HDM:~/deployment/TPO_deploy_LatestBI.sh
  scp -rp ../../config/update-stack/update-stack.py ansible@$IP_PSX_HDM:~/update-stack/update-stack.py
  scp -rp ../../config/update-stack/tpo-psx.cfg ansible@$IP_PSX_HDM:~/update-stack/tpo-psx.cfg
  ssh -tt ansible@$IP_PSX_HDM '/bin/sh -c '"'"'echo BECOME-SUCCESS- auf $(uname -n); \
    aws configure set region eu-central-1 && cd deployment && ./TPO_deploy_LatestBI_al23.sh '$psxEnv' '"'"''
else
  echo DEBUG: PSX Jenkins erkannt
  ./TPO_deploy_LatestBI_al23.sh $psxEnv
fi