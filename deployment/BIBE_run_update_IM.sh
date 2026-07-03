#!/bin/bash
set -e
BIBE_IM=$1
SNAPSHOT_ID=$(aws ec2 --region eu-central-1 describe-instances --filters "Name=tag:Name,Values=${BIBE_IM}" --query 'Reservations[*].Instances[*].InstanceId' --output text | tail -1)
BIBE_IM_IP=$(aws ec2 --region eu-central-1 describe-instances --filters "Name=tag:Name,Values=${BIBE_IM}" --query 'Reservations[*].Instances[*].PrivateIpAddress' --output text | tail -1)

#already_running=$(
aws ec2 --region eu-central-1 start-instances --instance-ids $SNAPSHOT_ID
echo "waiting for instance to start ($BIBE_IM_IP $SNAPSHOT_ID)"
aws ec2 --region eu-central-1 wait instance-running --instance-ids $SNAPSHOT_ID
aws ec2 --region eu-central-1 wait instance-status-ok --instance-ids $SNAPSHOT_ID
aws ec2 --region eu-central-1 wait system-status-ok --instance-ids $SNAPSHOT_ID
sleep 20
ssh -tt  -o StrictHostKeyChecking=no ansible@$BIBE_IM_IP sudo /bin/dnf update -y
