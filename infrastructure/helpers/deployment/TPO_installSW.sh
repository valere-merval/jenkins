#!/bin/bash
set -e
psxEnv=$1
skipEnvs=$(</var/jenkins_home/jenkinsDateneinsatzConfig/generated/envs_deactivated)
if [[ ${psxEnv} =~ ^(${skipEnvs})$ ]]; then
  echo skipping psx${psxEnv} TPO SW Install
  exit 0
fi
IP=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=tpo-psx$psxEnv*" --query 'Reservations[*].Instances[*].PrivateIpAddress' --output text)

ssh -o StrictHostKeyChecking=no -tt ansible@$IP sudo -u vbf_k90 '/bin/sh -c '"'"'echo BECOME-SUCCESS- auf $(uname -n); \
    export PATH=$PATH:/app/kurs90/vbf_k90/bin;cd /app/kurs90/vbf_k90/tools; \
    ./syncS3_install_direct_Programm.sh --restart && ./verbindungstest.sh'"'"''
