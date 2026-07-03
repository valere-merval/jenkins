#!/bin/bash
if [[ $1 =~ ^(k|l|q|h|i|j|n|m)$ ]]; then
  UMGEBUNG=$1
else
  echo Kein Umgebung gegeben
  exit 1
fi

if [[ $1 == *k* ]]; then
  STACKNAME=tpo-psxk-tt-appsrv
elif [[ $1 == *l* ]]; then
  STACKNAME=tpo-psxl-at-appsrv
elif [[ $1 == *q* ]]; then
  STACKNAME=tpo-psxq-tt-appsrv
elif [[ $1 == *h* ]]; then
  STACKNAME=tpo-psxh-st-appsrv
elif [[ $1 == *i* ]]; then
  STACKNAME=tpo-psxi-tt-appsrv
elif [[ $1 == *j* ]]; then
  STACKNAME=tpo-psxj-at-appsrv
elif [[ $1 == *n* ]]; then
  STACKNAME=tpo-psxn-tt-appsrv
elif [[ $1 == *m* ]]; then
  STACKNAME=tpo-psxm-st-appsrv
else
  echo not specified yet
  exit
fi
shift

LATEST_BASE_AMI=$(aws ec2 describe-images --filters Name=name,Values=dbv-amzn2-base* --owners self --query 'sort_by(Images, &CreationDate)[-1].ImageId' --output text)
#==========================================================
#SETTINGS
CLFS_LINK='https://s3.eu-central-1.amazonaws.com/556971410989-common-daten/temp_psx/cloudformation/cfn-tpo-psx.yml'

aws cloudformation create-change-set --stack-name $STACKNAME  --change-set-name cs-$STACKNAME --change-set-type UPDATE \
--template-url $CLFS_LINK --parameters \
ParameterKey=Environment,UsePreviousValue=true \
ParameterKey=SubEnvironment,UsePreviousValue=true \
ParameterKey=InstanceType,UsePreviousValue=true \
ParameterKey=VolumeSize,UsePreviousValue=true \
ParameterKey=AmiId,ParameterValue=$LATEST_BASE_AMI \
ParameterKey=Subnets,UsePreviousValue=true \
ParameterKey=AsgSize,UsePreviousValue=true \
ParameterKey=CreateNetworkLoadBalancer,UsePreviousValue=true \
ParameterKey=WaitForSuccessSignal,UsePreviousValue=true \
--capabilities CAPABILITY_IAM
