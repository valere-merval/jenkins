#!/bin/bash
set -e
BIBE_IM=$1
SERVER_VERSION=$2
version_line="HAFAS <server.exe> Version: 5.45.DB.NVS."
IP=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=${BIBE_IM}" --query 'Reservations[*].Instances[*].PrivateIpAddress' --output text)

found_version_line='false'
echo "DEBUG: search SERVER version line: $version_line"
while read -r line
do
  echo "DEBUG: $line"
  if [[ ${line} =~ .*"$version_line".* ]]; then
    found_version_line='true'
    if [[ ${line} =~ .*"$version_line${SERVER_VERSION:0:3} [".* ]]; then
      extracted_date_string="$(echo $line | cut -d'[' -f2 | cut -d']' -f1)"
      transformed_string=$(date -d"$extracted_date_string" +%Y-%m-%d)
      echo "DEBUG: transformed_string from server version: $transformed_string"
      if [[ "${SERVER_VERSION:4:10}" != "${transformed_string}" ]]; then
        echo "WARNING: !!!!! ATTENTION !!!!! date is not as expected: $transformed_string vs. ${SERVER_VERSION:4:10}"
      fi
      echo "WARNING: same SERVER version is deployed"
      exit 111
    fi
  fi
done <<< $(ssh  -o StrictHostKeyChecking=no -tt ansible@$IP sudo -u nvs '/bin/sh -c '"'"'echo BECOME-SUCCESS- auf $(uname -n); \
    LD_LIBRARY_PATH=/home/nvs/lib /home/nvs/auskunft/server/bin/server.exe -v'"'"'')
if [[ "$found_version_line" == 'false' ]]; then
  echo "WARNING: !!!  ATTENTION  !!! the SERVER version is not as expected."
  exit 111
fi
