#!/bin/bash
set -e
current_pe_release=$1
PE_Subversion=$2
version_line='$PEInfo: PE-LIB-Version '
#AMZN2_switch=$3
BIBE_IM=$3
IP=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=${BIBE_IM}" \
    --query 'Reservations[*].Instances[*].PrivateIpAddress' --output text)

found_version_line='false'
echo "DEBUG: search PE version line: ${version_line}${current_pe_release:2:2}.${current_pe_release:4:2}"
while read line
do
  echo "DEBUG: $line"
  if [[ ${line} =~ .*"${version_line}${current_pe_release:2:2}.".* ]]; then
    found_version_line='true'
    if [[ ${line} =~ .*"${version_line}${current_pe_release:2:2}.${current_pe_release:4:2}.${PE_Subversion}".* ]]; then
      echo "WARNING: same PE version is deployed"
      exit 111
    fi
  fi
done <<< $(ssh  -o StrictHostKeyChecking=no -tt ansible@$IP sudo -u nvs '/bin/sh -c '"'"'echo BECOME-SUCCESS- auf $(uname -n); \
    strings /home/nvs/lib/libpe.so.0 | grep PE-LIB-Version'"'"'')
if [[ "$found_version_line" == 'false' ]]; then
  echo "WARNING: !!!  ATTENTION  !!! the PE version is not as expected."
  exit 111
fi
