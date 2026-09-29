#!/bin/bash
set -e
BIBE_IM=$1
psxEnv=$2

IM_IP=$(aws ec2 describe-instances  --filters "Name=tag:Name,Values=${BIBE_IM}"                  --query 'Reservations[*].Instances[*].PrivateIpAddress' --output text)
ENV_IP=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=nvs-psx${psxEnv}-bibe-hafas" --query 'Reservations[*].Instances[*].PrivateIpAddress' --output text)

PE_IM=$(ssh -o StrictHostKeyChecking=no -tt ansible@$IM_IP sudo -u nvs '/bin/sh -c '"'"'echo BECOME-SUCCESS- auf $(uname -n); \
    strings /home/nvs/lib/libpe.so.0'"'"'' | grep 'PEInfo: PE-LIB-Version')
PE_ENV=$(ssh -o StrictHostKeyChecking=no -tt ansible@$ENV_IP sudo -u nvs '/bin/sh -c '"'"'echo BECOME-SUCCESS- auf $(uname -n); \
    strings /home/nvs/lib/libpe.so.0'"'"'' | grep 'PEInfo: PE-LIB-Version')
SERVER_IM=$(ssh -o StrictHostKeyChecking=no -tt ansible@$IM_IP sudo -u nvs '/bin/sh -c '"'"'echo BECOME-SUCCESS- auf $(uname -n); \
    LD_LIBRARY_PATH=/home/nvs/lib /home/nvs/auskunft/server/bin/server.exe -v'"'"'' | grep 'HAFAS <server.exe> Version')
SERVER_ENV=$(ssh -o StrictHostKeyChecking=no -tt ansible@$ENV_IP sudo -u nvs '/bin/sh -c '"'"'echo BECOME-SUCCESS- auf $(uname -n); \
    LD_LIBRARY_PATH=/home/nvs/lib /home/nvs/auskunft/server/bin/server.exe -v'"'"'' | grep 'HAFAS <server.exe> Version')

echo "$PE_IM $PE_ENV $SERVER_IM $SERVER_ENV"

if [[ ( "$PE_IM" == "$PE_ENV" ) && ( "$SERVER_IM" == "$SERVER_ENV" ) ]]; then
  echo "same PE und SERVER ($BIBE_IM, $psxEnv)"
  exit
fi

echo "ERROR: !!!  ATTENTION  !!! the SERVER or PE version is not as expected."
exit 111