#!/bin/bash
set -e
current_pe_release=$1
pe_folder="/share/SOFTWARE/pe/pe-${current_pe_release:2:2}.${current_pe_release:4:2}/AL23"

if [ -z ${PSX_HDM_LOCAL+x} ]; then
IP_PSX_HDM=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=nvs-psx-hdm" --query 'Reservations[*].Instances[*].PrivateIpAddress' --output text)
ssh -o StrictHostKeyChecking=no -tt ansible@$IP_PSX_HDM '/bin/sh -c '"'"'echo BECOME-SUCCESS- auf $(uname -n); \
  aws s3 sync '$pe_folder' s3://556971410989-common-software/BIBE/pe/AL23 --no-progress'"'"''
else
  aws s3 sync $pe_folder s3://556971410989-common-software/BIBE/pe/AL23 --no-progress
fi