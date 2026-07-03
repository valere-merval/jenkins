#!/bin/bash
set -e
#use create-snapshot.py script directly instead
BIBE_IM=$1
COMMENT=$2
KM=$3

if [ -z ${PSX_HDM_LOCAL+x} ]; then
IP_PSX_HDM=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=nvs-psx-hdm" --query 'Reservations[*].Instances[*].PrivateIpAddress' --output text)
scp -rp ../create-snapshot.py ansible@$IP_PSX_HDM:~/create-snapshot.py
ssh -tt ansible@$IP_PSX_HDM '/bin/sh -c '"'"'echo BECOME-SUCCESS- auf $(uname -n); \
  aws configure set region eu-central-1 && ./create-snapshot.py --im '${BIBE_IM}' --comment "'${COMMENT}'" --KM "'${KM}'"	'"'"''
else
  ../create-snapshot.py --im "${BIBE_IM}" --comment "${COMMENT}" --KM "${KM}"
fi