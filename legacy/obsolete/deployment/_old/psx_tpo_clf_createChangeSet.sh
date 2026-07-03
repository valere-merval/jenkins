#!/bin/bash
#==========================================================
#SETTINGS
CLFS_LINK='https://s3.eu-central-1.amazonaws.com/556971410989-common-daten/temp_psx/cloudformation/tpo_clfs_psx20191010.yml'
SUBNETS='subnet-038cbd42d09de3d39' #,subnet-0cc2a32bb6899f17a\,subnet-030f8fb1883a9381b'
#==========================================================
ENVIRONMENT=psx$1
SUBENVIRONMENT=$2
INSTANCE_TYPE=$3
SUFFIX=$4
STACKNAME=tpo-$ENVIRONMENT-$SUBENVIRONMENT-appsrv$SUFFIX
LATEST_BASE_AMI=$(aws ec2 describe-images --filters Name=name,Values=dbv-amzn2-base* --owners self --query 'sort_by(Images, &CreationDate)[-1].ImageId')

if [[ $1 =~ ^(k|l|q|h|i|j|n|m)$ && $#>2 ]];
then
aws cloudformation create-change-set --stack-name $STACKNAME  --change-set-name cs-$STACKNAME --change-set-type CREATE \
--template-url $CLFS_LINK \
--parameters \
ParameterKey=Environment,ParameterValue=$ENVIRONMENT \
ParameterKey=SubEnvironment,ParameterValue=$SUBENVIRONMENT \
ParameterKey=InstanceType,ParameterValue=$INSTANCE_TYPE \
ParameterKey=AmiId,ParameterValue=$LATEST_BASE_AMI \
ParameterKey=Subnets,ParameterValue=$SUBNETS \
ParameterKey=AsgSize,ParameterValue=1 \
ParameterKey=CreateNetworkLoadBalancer,ParameterValue=true \
--capabilities CAPABILITY_IAM \
--tags \
Key=ApplicationName,Value=tpo \
Key=Subsystem,Value=appsrv \
Key=Environment,Value=$ENVIRONMENT \
Key=CostReference,Value=F-270001-51-03 \
Key=Name,Value=$STACKNAME

else
  echo 'USAGE EXAMPLE: $.sh l st t3.large [-lauf1] (update CLFS link and subnets if changed)'
  exit 1
fi
