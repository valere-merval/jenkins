#!/bin/bash
set -e
RELEASE=$1
KM_VERSION=$2

#check if svn repo exists and there are required archives
func_check_svn_repo()
{
  SWN="^vl*|^twe*"
  ARCHALT=$(svn ls --username $SVN_USER --password $SVN_PW --no-auth-cache $URLNAME | egrep $SWN | grep ami)
  if [ -z "${ARCHALT}" ]
  then
    echo -e "ERROR: Es konnte kein Archiv-File gefunden werden. Bitte prüfen Sie das Repository manuell"
  fi
  echo "@@@ archives found: --> "$ARCHALT
}

#verify and checkout SW distribution into local directory
PROG_ARCHIVE_DIR=tpo_archives
func_svnsync_tpo_software()
{
  local rel=$1
  local ver=$2
  URLNAME=https://swd.noncd.rz.db.de/svn/pvlk-bin-1/version/${rel}/avs/KM/${ver}/dist
  func_check_svn_repo $URLNAME
  cd "${WORKSPACE}"
  rm -rf $PROG_ARCHIVE_DIR
  mkdir -p $PROG_ARCHIVE_DIR
  cd $PROG_ARCHIVE_DIR
  svn co --username $SVN_USER --password $SVN_PW --no-auth-cache $URLNAME
  mv dist/twe* .
  mv dist/vl* .
  rm -rf dist
}

func_svnsync_tpo_software ${RELEASE} ${KM_VERSION}

if [ -z ${PSX_HDM_LOCAL+x} ]; then
  IP_PSX_HDM=$(aws ec2 --region eu-central-1 describe-instances --filters "Name=tag:Name,Values=nvs-psx-hdm" --query 'Reservations[*].Instances[*].PrivateIpAddress' --output text)
  scp -rp "${WORKSPACE}/${PROG_ARCHIVE_DIR}" ansible@$IP_PSX_HDM:/tmp
  ssh -tt ansible@$IP_PSX_HDM '/bin/sh -c '"'"'echo BECOME-SUCCESS- auf $(uname -n); \
  aws s3 sync /tmp/'${PROG_ARCHIVE_DIR}' s3://556971410989-common-software/TPO/'${RELEASE}'/'${KM_VERSION}' --size-only --no-progress; \
  rm /tmp/'${PROG_ARCHIVE_DIR}' -rf'"'"''
else
  echo DEBUG: PSX Jenkins erkannt 
  aws s3 sync "${WORKSPACE}/${PROG_ARCHIVE_DIR}" "s3://556971410989-common-software/TPO/${RELEASE}/${KM_VERSION}" --size-only --no-progress
fi