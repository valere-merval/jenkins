#!/bin/bash
#
# runScriptOnApp.sh <app>
#

#
# Jumphost
#
USER=ddragisi
USER_ANSIBLE=ansible
JUMPHOST=bastion.dbv3-test.comp.db.de

#
# Bibe
#
BIBE_KEY=bibe-hafas
BIBE_TUSER=nvs
BIBE_TOOLS_DIR=/bibe/tools
BIBE_RESTART_ANSIBLE=datenEinsatz_resetBIBE_with_playbook.sh
BIBE_INSTALL_DATA=installDatapackages.sh
BIBE_INSTALL_SW=installSoftware.sh
BIBE_RESTART=restartBibe.sh

#
# TPO
#
TPO_KEY=tpo
TPO_TUSER=vbf_k90
TPO_TOOLS_DIR=/app/kurs90/vbf_k90/tools
# uses PMAN conf files
#TPO_INSTALL_DATA=syncS3_install_direct_CommonDaten.sh
# uses depconf file
TPO_INSTALL_DATA=installDataTpo.sh
TPO_INSTALL_SW=syncS3_install_direct_Programm.sh
TPO_RESTART=restartTpo.sh
TPO_STOP=stopTpo.sh
TPO_START=startTpo.sh

#
# Color
#
RED='\033[0;31m'
BLUE='\033[1;34m'
GREEN='\033[0;32m'
NC='\033[0m'

function usage {

	echo -e "${GREEN}Application Smart Installer${NC}"
	echo ""
	echo "Data and software installation on a PSX application servers Bibe und TPO."
	echo "Rebot of PSX application servers."
	echo ""
	echo "Usage:"
	echo "	asi -h 		Display this help message."
	echo "	asi -a <app> 	Application server e.g. (nvs-psxl-bibe-hafas, tpo-psxl-appsrv)."
	echo "	asi -d 		Command to execute on remote server -> data installation."
	echo "	asi -s 		Command to execute on remote server -> software installation."
	echo "	asi -r 		Command to execute on remote server -> restart application."
	echo "	asi -p 		Command to execute on remote server -> stop application."
	echo "	asi -t 		Command to execute on remote server -> start application."
	echo ""
	echo "Author: Dragisa Dragisic, 2020"

}

function setVariable {

	local var=$1
	shift
	if [ -z "${!var}" ]; then
		eval "$var=\"$@\""
	else
		echo "Error: $var already set"
		usage
	fi
}

function findAppType {
	app=$1
	app_type=$(echo $app | cut -d'-' -f1)
}

function findAppEnv {
	app=$1
	app_env=$(echo $app | cut -d'-' -f2)
}

function findAppCarrier {
	env=$1
	app_carrier=${env:3:1}
}

function getIpFromAWS {
	app=$1
	ip=(`aws ec2 describe-instances --filters "Name=tag:Name,Values=${app}" --region eu-central-1 --query "Reservations[*].Instances[*].NetworkInterfaces[0].PrivateIpAddress" --output text`)
}

function runScript {
	ip=$1
#	echo -e ${BLUE}Running $SCRIPT on $app IP=$ip user $TUSER${NC} ...
	echo -e Running $SCRIPT on $app IP=$ip user $TUSER ...

	ssh -o StrictHostKeyChecking=no -tt $USER_ANSIBLE@$ip sudo -u $TUSER '/bin/sh -c '"'"'echo BECOME-SUCCESS- run '${HOME_DIR}/${SCRIPT}' on $(uname -n); \
		export PATH=$PATH:/app/kurs90/vbf_k90/bin; cd '${HOME_DIR}'; \
		./'${SCRIPT}' '"'"''

#	ssh -o StrictHostKeyChecking=no -t -J $USER@$JUMPHOST $USER@$ip "sudo su - $TUSER << EOF
#	ssh -o StrictHostKeyChecking=no -tt $USER_ANSIBLE@$ip sudo -u $TUSER "/bin/sh -c << EOF
#$SCRIPT
#EOF"
	echo -e Done at `date`.
	echo ""
}

function runScriptLocal {
	carrier=$1
	echo -e Running $SCRIPT on Jenkins with Carrier=$carrier App=$app User=$TUSER ...
	sh ./$SCRIPT $carrier
	echo -e Done at `date`.
	echo ""
}
#
# main
#
unset HOME_DIR SCRIPT app app_type app_env ip install_data install_sw restart

#
# parse args
#
while getopts "hdsrpta:" opt; do
	case ${opt} in
		d )
			setVariable command install_data ;;
		s )
			setVariable command install_sw ;;
		r )
			setVariable command restart ;;
		p )
			setVariable command stop ;;
		t )
			setVariable command start ;;
		a )
			setVariable app $OPTARG ;;
		h | \? )
			usage
			exit 0 ;;
	esac
done

[ -z "$app" ] && usage && exit 0
[ -z "$command" ] && usage

#echo -e ${BLUE}Running ASI with app=${RED}$app${BLUE}, command=${RED}$command${BLUE} at `date`${NC}.
echo -e Running ASI with app=$app, command=$command at `date`.
echo ""

findAppType $app
#echo -e ${BLUE}Application type=${RED}$app_type${NC}.

findAppEnv $app
#echo -e ${BLUE}Application env=${RED}$app_env${NC}.

findAppCarrier $app_env
#echo -e ${BLUE}Application carrier=${RED}$app_carrier${NC}.

echo -e Application type=$app_type env=$app_env carrier=$app_carrier.


if [ -n "$app_type" ]; then
	case $app_type in
		nvs )
			# search for Bibe Server
			SERVER_KEY=$BIBE_KEY
			getIpFromAWS $app
			TUSER=$BIBE_TUSER
			HOME_DIR=$BIBE_TOOLS_DIR
			case $command in
				install_data )
					# install data & restart (uses TUSER, SCRIPT)
					SCRIPT=${BIBE_RESTART_ANSIBLE}
					runScriptLocal $app_carrier
					;;
				install_sw )
					# install sw (uses TUSER, SCRIPT)
					SCRIPT=${BIBE_INSTALL_SW}
					runScript $ip
					;;
				restart )
					# restart (uses TUSER, SCRIPT)
					SCRIPT=${BIBE_RESTART}
					runScript $ip
					;;
				stop )
					# stop (uses TUSER, SCRIPT)
					;;
				start )
					# start (uses TUSER, SCRIPT)
					;;
			esac
			;;
		tpo )
			# search for TPO Server
			SERVER_KEY=$TPO_KEY
			getIpFromAWS $app
			TUSER=$TPO_TUSER
			HOME_DIR=$TPO_TOOLS_DIR
			case $command in
				install_data )
					# install data (uses TUSER, SCRIPT)
					SCRIPT="${TPO_INSTALL_DATA}"
					runScript $ip
					;;
				install_sw )
					# install sw (uses TUSER, SCRIPT)
					SCRIPT="${TPO_INSTALL_SW}"
					runScript $ip
					;;
				restart )
					# restart (uses TUSER, SCRIPT)
					SCRIPT=${TPO_RESTART}
					runScript $ip
					;;
				stop )
					# restart (uses TUSER, SCRIPT)
					SCRIPT=${TPO_STOP}
					runScript $ip
					;;
				start )
					# restart (uses TUSER, SCRIPT)
					SCRIPT=${TPO_START}
					runScript $ip
					;;
			esac
			;;
	esac
fi

#echo -e ${GREEN}Command $command on $app IP=$ip at `date` done!!!${NC}
echo -e Command $command on $app IP=$ip at `date` done!!!
