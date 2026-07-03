#!/bin/bash
set -e
#note - update csv direct in S3 Bucket common-daten/temp_psx/sw-tpo-psx?.csv should be prefered method
csv_string=$1
psxEnv=$2

if [ -z ${PSX_HDM_LOCAL+x} ]; then
IP_PSX_HDM=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=nvs-psx-hdm" --query 'Reservations[*].Instances[*].PrivateIpAddress' --output text)
# assume special role for IAM permissions
#unset AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN AWS_SECURITY_TOKEN AWS_ACCESS_KEY AWS_SECRET_KEY AWS_DELEGATION_TOKEN
#ACCOUNT_ID=$(aws sts get-caller-identity --query 'Account' --output text)
#ROLE_NAME=infra-common-jenkins-DataMgrRole
#SESSION_NAME="PSX_AMI_UPDATE_${BUILD_NUMBER}"
#CREDENTIALS_TRIPLE=($(aws sts assume-role --role-arn "arn:aws:iam::${ACCOUNT_ID}:role/${ROLE_NAME}" --role-session-name "$SESSION_NAME" --query 'Credentials.[AccessKeyId,SecretAccessKey,SessionToken]' --output text))
#export AWS_DEFAULT_REGION="eu-central-1"
#export AWS_ACCESS_KEY_ID="${CREDENTIALS_TRIPLE[0]}"
#export AWS_SECRET_ACCESS_KEY="${CREDENTIALS_TRIPLE[1]}"
#export AWS_SESSION_TOKEN="${CREDENTIALS_TRIPLE[2]}"

ssh -tt ansible@$IP_PSX_HDM '/bin/sh -c '"'"'echo BECOME-SUCCESS- auf $(uname -n); aws configure set region eu-central-1 && \
  echo "'${csv_string}'" >tmp && aws s3 cp ./tmp s3://556971410989-common-software/TPO/sw-tpo-psx'$psxEnv'.csv '"'"''
else
  echo DEBUG: PSX Jenkins erkannt
  #check if version is same
  while read -r line
  do
    if [ "${line}" == "${csv_string}" ]; then
      echo WARNING: same SW version is deployed !!!
      exit 111
    fi
    break
  done <<< "$(aws s3 cp s3://556971410989-common-software/TPO/sw-tpo-psx${psxEnv}.csv -)"

  echo "${csv_string}" >tmp && aws s3 cp ./tmp s3://556971410989-common-software/TPO/sw-tpo-psx${psxEnv}.csv
  rm tmp -rf
fi