#!/bin/bash
set -e
current_pe_release=$1
PE_Subversion=$2
#AMZN2_switch=$3
BIBE_IM=$3
IP=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=${BIBE_IM}" \
    --query 'Reservations[*].Instances[*].PrivateIpAddress' --output text)

ssh  -o StrictHostKeyChecking=no -tt ansible@$IP sudo -u nvs '/bin/sh -c '"'"'echo BECOME-SUCCESS- auf $(uname -n); \
    cd /home/nvs/bin && ./install_bibe_aws.sh --PE_AL23 '${current_pe_release:2:2}'.'${current_pe_release:4:2}'.'${PE_Subversion}''"'"''
