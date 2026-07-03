#!/bin/bash

if [[ $1 =~ ^(k|l|q|h|i|j|n|m)$ ]]; then
  UMGEBUNG=$1
else
  echo Kein Umgebung gegeben
  exit 1
fi

IP=$(ec2admin list tpo-psx$UMGEBUNG | grep -oE '(10\.105\.)((1?[0-9][0-9]?|2[0-4][0-9]|25[0-5])\.)(1?[0-9][0-9]?|2[0-4][0-9]|25[0-5])')

ssh -t $IP sudo -u vbf_k90 '/bin/sh -c "echo BECOME-SUCCESS- auf $(uname -n); \
export PATH=$PATH:/app/kurs90/vbf_k90/bin;'$2'"'
