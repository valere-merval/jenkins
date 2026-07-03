#!/bin/bash

help() {
#  echo "Programm/Server Einsatz for PSX BiBe Image Master"
  echo "usage: $.sh [-db|--debug] (--name ... )"
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
       -n|--name)
       NAME=$2
       shift 2
       ;;
       *)
       help
       ;;
  esac
done

COMMAND="sudo rootshell"

if [ -z "$NAME" ]; then
  [ $DEBUG_MODE ] && echo "missing name"
  help
fi

IP=$(ec2admin list $NAME | grep -oE '(10\.105\.)((1?[0-9][0-9]?|2[0-4][0-9]|25[0-5])\.)(1?[0-9][0-9]?|2[0-4][0-9]|25[0-5])')
ID=$(ec2admin list $NAME | grep -oE 'i-[0-9a-f]*')
[ $DEBUG_MODE ] && echo $ID
aws ec2 start-instances --instance-ids $ID --query 'StartingInstances[*].CurrentState.Name' --output text
echo "waiting for instance to start ($IP $ImMaster )"

aws ec2 wait instance-running --instance-ids $ID
[ $DEBUG_MODE ] && echo instance is started
[ $DEBUG_MODE ] && ec2admin list $NAME

sleep 3
ssh -t $IP $COMMAND 

