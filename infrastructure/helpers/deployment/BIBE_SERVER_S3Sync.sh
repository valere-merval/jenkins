#!/bin/bash
set -e
current_server_release=$1
server_folder="/share/SOFTWARE/hafas/nvs/${current_server_release}"
if [ -z ${PSX_HDM_LOCAL+x} ]; then
IP_PSX_HDM=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=nvs-psx-hdm" --query 'Reservations[*].Instances[*].PrivateIpAddress' --output text)
ssh -tt ansible@$IP_PSX_HDM '/bin/sh -c '"'"'echo BECOME-SUCCESS- auf $(uname -n); \
 aws s3 sync '${server_folder}' s3://556971410989-common-software/BIBE/SERVER --no-progress'"'"''
else
  aws s3 sync "${server_folder}" s3://556971410989-common-software/BIBE/SERVER --no-progress
fi