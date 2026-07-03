#!/bin/bash
set -e
if [[ $1 =~ ^(k|l|q|h|i|j|n|m)$ ]]; then
  UMGEBUNG=$1
else
  echo Keine / nicht unterstuetzte Umgebung gegeben
  exit 1
fi


cd ../update-stack

Name=tpo-psx${UMGEBUNG}-appsrv

#Config vorbereiten
aws ec2 describe-images --filters Name=name,Values="Amazon Linux 2023*" --owners self --query 'sort_by(Images, &CreationDate)[-1].Name'
LATEST_BASE_AMI=$(aws ec2 describe-images --filters Name=name,Values="Amazon Linux 2023*" --owners self --query 'sort_by(Images, &CreationDate)[-1].ImageId' --output text)

sed -i -e '/Name:/c\Name: '$Name -e '/AmiId:/c\AmiId: '$LATEST_BASE_AMI tpo-psx.cfg 
cat tpo-psx.cfg

############################## temporary, because no rights for direct update-stack, even with jenkins ####################################
#create change set with latest AMI 
./update-stack.py tpo-psx.cfg

