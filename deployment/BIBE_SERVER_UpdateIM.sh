#!/bin/bash
set -e
BIBE_IM=$1
SERVER_VERSION=$2
IP=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=${BIBE_IM}" --query 'Reservations[*].Instances[*].PrivateIpAddress' --output text)
ssh  -o StrictHostKeyChecking=no -tt ansible@$IP sudo -u nvs '/bin/sh -c '"'"'echo BECOME-SUCCESS- auf $(uname -n); \
cd /home/nvs/bin && ./install_bibe_aws.sh --SERVER '${SERVER_VERSION}''"'"''
