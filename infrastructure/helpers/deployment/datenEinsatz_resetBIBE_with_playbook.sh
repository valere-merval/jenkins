#!/bin/bash
set -e
#backup solution: use terminate_psx_bibe instead of this script (terminate instance instead of restart)
psxEnv=$1
skipEnvs=$(</var/jenkins_home/jenkinsDateneinsatzConfig/generated/envs_deactivated)
if [[ ${psxEnv} =~ ^(${skipEnvs})$ ]]; then
  echo skipping psx${psxEnv} BiBe reset
  exit 0
fi
cd ../../infrastructure/ansible
if [[ ${psxEnv} =~ ^(k|l|q|h|i|j|n|m)$ ]]; then
  IP=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=nvs-psx${psxEnv}-bibe-hafas" --query 'Reservations[*].Instances[*].PrivateIpAddress' --output text)
  ssh -o StrictHostKeyChecking=no -tt ansible@$IP /bin/sh -c "echo BECOME-SUCCESS- auf \$(uname -n); \
  cd /home/ansible/ansible-playbook-nvsbibe && \
  ansible-playbook local.yml -c local --skip-tags cronjobs -e skip_restart_handler=False --limit=\$(ec2-metadata --local-ipv4 | awk '{print \$2}')"
  # ansible-playbook plandaten-bibe.yml -c local -e environment_name=psx${psxEnv} -e skip_restart_handler=True -v && \
  # ansible-playbook preisdaten-bibe.yml -c local -e environment_name=psx${psxEnv} -e skip_restart_handler=True -v && \
  # ansible-playbook stammdaten-bibe.yml -c local -e environment_name=psx${psxEnv} -e skip_restart_handler=False -v"

else
  echo Keine Umgebung vorhanden
  exit 1
fi
