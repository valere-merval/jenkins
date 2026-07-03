#!/bin/bash
if [[ $1 =~ ^(k|l|q|h|i|j|n|m)$ ]]; then
  UMGEBUNG=$1
else
  echo Kein Umgebung gegeben
  exit 1
fi

if [[ $1 == *k* ]]; then
  STACKNAME=nvs-psxk-bibe
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
  STACKNAME=tpo-psxn-at-appsrv
elif [[ $1 == *m* ]]; then
  STACKNAME=tpo-psxm-at-appsrv
else
  echo not specified yet
  exit
fi
shift

#==========================================================
#SETTINGS
CLFS_LINK='https://s3.eu-central-1.amazonaws.com/556971410989-common-daten/temp_psx/cloudformation/db-app-nvs.yml'

aws cloudformation create-change-set --stack-name nvs-psx$UMGEBUNG-bibe  --change-set-name cs-psx$UMGEBUNG-bibe --change-set-type UPDATE \
--template-url $CLFS_LINK --parameters \
ParameterKey=EnvironmentName,UsePreviousValue=true \
ParameterKey=AutoShutdown,UsePreviousValue=true \
ParameterKey=TestApplication,UsePreviousValue=true \
ParameterKey=PtvStackName,UsePreviousValue=true \
ParameterKey=NvsBibePlaybookVersion,UsePreviousValue=true \
ParameterKey=NvsBibeAutoScalingMinSize,UsePreviousValue=true \
ParameterKey=NvsBibeAutoScalingMaxSize,UsePreviousValue=true \
ParameterKey=NvsBibeAutoScalingDesiredCapacity,UsePreviousValue=true \
ParameterKey=NvsBibeInstanceType,UsePreviousValue=true \
ParameterKey=NvsBibeGoldenImageAmi,UsePreviousValue=true \
ParameterKey=NvsBibeVolumeSize,UsePreviousValue=true \
--capabilities CAPABILITY_IAM
