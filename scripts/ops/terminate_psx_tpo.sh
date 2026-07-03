#!/bin/bash
if [[ $1 =~ ^(k|l|q|h|i|j|n|m)$ ]];
then
skipEnvs=$(</var/jenkins_home/jenkinsDateneinsatzConfig/generated/envs_deactivated)
if [[ ${1} =~ ^(${skipEnvs})$ ]]; then
  echo skipping psx${1} TPO terminate
  exit 0
fi
  Server="tpo-psx$1*-appsrv"
  ID="$(ec2admin list $Server | grep -oE 'i-[0-9a-f][0-9a-f]+')"
  echo $ID | tr '\n' ' '
  aws ec2 terminate-instances --instance-ids $ID
else
  echo "No argument supplied (expected psx enviroment - k h l q i j n m... )"
  exit 1
fi
