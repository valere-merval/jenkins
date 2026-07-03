#!/bin/bash

help() {
  echo "Programm/Server Einsatz for PSX BiBe Image Master"
  echo "usage: $.sh [-db|--debug] (--pe NN.NN.*|--server *-20??-??-?? --imageVersion 1908 )"
  exit 1
}

while [[ $# -gt 0 ]]
do
  key="$1"
  case $key in
       -db|--debug)
       DEBUG_MODE=true
       shift
       ;;
       -pe|--pe)
       PE_VERSION=$2
       IMAGE_VERSION=${PE_VERSION:0:2}${PE_VERSION:3:2}
       shift 2
       ;;
       -srv|--server)
       SERVER_VERSION=$2
       shift 2
       ;;
       -iv|--imageVerson)
       IMAGE_VERSION=$2
       shift 2
       ;;
       *)
       help
       ;;
  esac
done

if [[ ! $PE_VERSION =~ ^([1-3][0-9]\.[0-1][0-9]\..*)$ ]]; then
[ $DEBUG_MODE ] && echo "wrong PE VERSION format"
if [[ ! $SERVER_VERSION =~ ^(.+-20[0-9]{2}-[0-1][0-9]-[0-3][0-9])$ ]]; then
  [ $DEBUG_MODE ] && echo "wrong SERVER VERSION format"
  help
fi
fi

COMMAND="~/download_bibeSW_aws.sh --PE $PE_VERSION"
COMMAND2="~/scripts/install_bibe_aws.sh --PE $PE_VERSION"
if [ -z "$PE_VERSION" ]; then
   COMMAND="~/download_bibeSW_aws.sh --SERVER $SERVER_VERSION"
   COMMAND2="~/scripts/install_bibe_aws.sh --SERVER $SERVER_VERSION"
   if [ -z "$IMAGE_VERSION" ]; then
       [ $DEBUG_MODE ] && echo "Server einsatz ohne imageMaster Angabe"
       help
   fi
fi

ImMaster=nvs-psx-bibe-imageMaster-$IMAGE_VERSION
IP=$(ec2admin list $ImMaster | grep $ImMaster'$' | grep -oE '(10\.105\.)((1?[0-9][0-9]?|2[0-4][0-9]|25[0-5])\.)(1?[0-9][0-9]?|2[0-4][0-9]|25[0-5])')
ID=$(ec2admin list $ImMaster | grep $ImMaster'$' | grep -oE 'i-[0-9a-f]*')
[ $DEBUG_MODE ] && echo $ID
aws ec2 start-instances --instance-ids $ID --query 'StartingInstances[*].CurrentState.Name' --output text
echo "waiting for instance to start ($IP $ImMaster )"

aws ec2 wait instance-running --instance-ids $ID
[ $DEBUG_MODE ] && echo instance is started
[ $DEBUG_MODE ] && ec2admin list $ImMaster

ssh -t $IP '/bin/sh -c "echo $(whoami)auf $(uname -n);'"$COMMAND"'"'
ssh -t $IP sudo -u nvs '/bin/sh -c "echo BECOME-SUCCESS- auf $(uname -n);'"$COMMAND2"'; \
LD_LIBRARY_PATH=/app/nvs/home/nvs/lib /app/nvs/home/nvs/auskunft/server/bin/server.exe -v"'

