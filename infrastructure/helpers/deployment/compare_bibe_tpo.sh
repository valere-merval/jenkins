#!/bin/bash
set -e
# parameter $1:
if [ $# -lt 2 ]; then
echo 'parameter $1:'
echo '     D - Data'
echo '     P - Programm'
echo '     A - All info'
echo 'expect at lease 1 another parameter (h l i j k q n m)'
exit
fi

### print out infos about bibe and tpo servers
func_bibe_tpo_infos()
{
for server in "$@"
do
  if ! [[ $server =~ ^(k|l|q|h|i|j|n|m)$ ]]; then
    echo !!! ERROR $server is not PSX Envinronment
    exit 1
  fi
  BiBe_IP=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=nvs-psx$server-bibe-hafas" --query 'Reservations[*].Instances[*].PrivateIpAddress' --output text | tail -n 1)
  ssh-keygen -R $BiBe_IP >/dev/null 2>&1
  ssh-keyscan $BiBe_IP >> ~/.ssh/known_hosts 2>/dev/null
  # cat ./compare_bibe_tpo_info_bibe | ssh -oStrictHostKeyChecking=no ansible@$BiBe_IP '/bin/sh'
  ssh -oStrictHostKeyChecking=no ansible@$BiBe_IP /bin/sh <<'EOC'
ps -eF | grep nvs.*server[.]exe.*nvsbibefork | wc -l | awk '{print "NVS processes running: "$1}' | sed 's/ 0/ 0 !!!!! ATTENTION !!!!!/g'
ps -eF | grep nvs.*server[.]exe.*abobibefork | wc -l | awk '{print "ABO processes running: "$1}' | sed 's/ 0/ 0 !!!!! ATTENTION !!!!!/g'
if [ $(df -m . | grep -o [0-9][0-9]*% | sed 's/\%//') -ge "90" ]; then echo '!!!!! ATTENTION CAUTION DISK FULL !!!!!'; fi
LD_LIBRARY_PATH=/home/nvs/lib /home/nvs/auskunft/server/bin/server.exe -v
strings /home/nvs/lib/libpe.so.0 | grep PE-LIB-Version
echo === Preisdaten ===;jq -r '.package' /home/nvs/auskunft/preisdaten/???/data/*/package_info.json | sed  -e 's/\.zip//' -e 's/\_FULL\.tar\.bz2//' | sort
echo === Plandaten ===;jq -r '.package' /home/nvs/auskunft/plandaten/???/pools/*/package_info.json | sed -e 's/\.zip//' | sort
echo === Stammdaten ===;grep Package ~nvs/config/bdirekt/fachlich.version | sed -e 's:^.*/::' -e 's/\.zip//'
uname -r
EOC

  TPO_IP=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=tpo-psx$server*-appsrv" --query 'Reservations[*].Instances[*].PrivateIpAddress' --output text | tail -n 1)
  ssh-keygen -R $TPO_IP >/dev/null 2>&1
  ssh-keyscan $TPO_IP >> ~/.ssh/known_hosts 2>/dev/null
  # cat ./compare_bibe_tpo_info_tpo | ssh -oStrictHostKeyChecking=no ansible@$TPO_IP '/bin/sh'
  ssh -oStrictHostKeyChecking=no ansible@$TPO_IP /bin/sh <<'EOC'
ps -eF | grep vbf_k90 | grep 'httpd -f' | wc -l | awk '{print "APACHE processes running: "$1}' | sed 's/ 0/ 0 !!!!! ATTENTION !!!!!/g'
if [ $(df -m . | grep -o [0-9][0-9]*% | sed 's/\%//') -ge "90" ]; then echo '!!!!! ATTENTION CAUTION DISK FULL !!!!!'; fi
cat /app/kurs90/int/install/akt/version-prog
echo k90_EKTR19 $(cat /app/kurs90/int/install/akt/data/akt/dm/k90-daten-version)
echo KAM $(cat /app/kurs90/int/install/akt/data/akt/dm/version | sed 's/version=EPA3-\(Q\|K\|H\|L\)//g')
cat /app/kurs90/int/install/akt/data/akt/efz/?/version-plandat
cat /app/kurs90/int/install/akt/data/akt/twe/version-twedat
cat /app/kurs90/int/install/akt/data/akt/vv/version-vvdatnew
cat /app/kurs90/int/install/akt/data/akt/ltn/version-ltndat
cat /app/kurs90/int/install/akt/data/akt/ltbw/version-ltbwdat
/app/kurs90/vbf_k90/tools/verbindungstest.sh >/dev/null 2>&1
/app/kurs90/vbf_k90/tools/proc_count.sh | grep -v '1\|##\|end of\|vorschau' | sed 's/ 0/ 0 !!!!! ATTENTION !!!!!/g'
uname -r
EOC
done
}

func_live_check()
{
for server in "$@"
do
  if ! [[ $server =~ ^(k|l|q|h|i|j|n|m)$ ]]; then
    echo !!! ERROR $server is not PSX Envinronment
    exit 1
  fi
  echo "live check BiBe psx$server ELB 5540, 5590"
  # wget --timeout=10 -q -O- nvs-psx$server-bibe.dbv3-test.comp.db.de:5540 2>/dev/null | grep libv= >/dev/null
  wget --timeout=10 -q -t3 -O - nvs-psx$server-bibe.dbv3-test.comp.db.de:5540 2>/dev/null | grep --binary-file=text "libv=" >/dev/null
  # wget --timeout=10 -q -O- nvs-psx$server-bibe.dbv3-test.comp.db.de:5590 2>/dev/null | grep libv= >/dev/null
  wget --timeout=10 -q -t3 -O - nvs-psx$server-bibe.dbv3-test.comp.db.de:5590 2>/dev/null | grep --binary-file=text "libv=" >/dev/null
  # wget --timeout=10 -q -O- nvs-psx$server-bibe-hafas.dbv3-test.comp.db.de:5540 2>/dev/null | grep libv= >/dev/null
  wget --timeout=10 -q -t3 -O - nvs-psx$server-bibe-hafas.dbv3-test.comp.db.de:5540 2>/dev/null | grep --binary-file=text "libv=" >/dev/null
  # wget --timeout=10 -q -O- nvs-psx$server-bibe-hafas.dbv3-test.comp.db.de:5590 2>/dev/null | grep libv= >/dev/null
  wget --timeout=10 -q -t3 -O - nvs-psx$server-bibe-hafas.dbv3-test.comp.db.de:5590 2>/dev/null | grep --binary-file=text "libv=" >/dev/null
  echo "live check BiBe psx$server Bista 443"
  # wget --timeout=10 -q -O- https://nvs-psx$server-bibe-hafas.dbv3-test.comp.db.de:443  2>/dev/null | grep 'Bista-AWS/index.jsp">BiSta' >/dev/null
  wget --timeout=10 -q -t3 -O - https://nvs-psx$server-bibe-hafas.dbv3-test.comp.db.de:443  2>/dev/null | grep 'Bista-AWS/index.jsp">BiSta' >/dev/null
  TPO_IP=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=tpo-psx$server*-appsrv" --query 'Reservations[*].Instances[*].PrivateIpAddress' --output text | tail -n 1)
  ssh-keygen -R $TPO_IP >/dev/null 2>&1
  ssh-keyscan $TPO_IP >> ~/.ssh/known_hosts 2>/dev/null
  echo "live check TPO psx$server - proc_count"
  ssh -oStrictHostKeyChecking=no ansible@$TPO_IP '/bin/test -z "$(/app/kurs90/vbf_k90/tools/proc_count.sh | grep -v vorschau | grep '"'"' 0'"'"')"'
  echo "live check TPO psx$server - verbindungstest"
  ssh -oStrictHostKeyChecking=no ansible@$TPO_IP '/bin/test -z "$(/app/kurs90/vbf_k90/tools/verbindungstest.sh | grep '"'"'WGET Test failed'"'"')"'
done
}

### filter settings (Program/Data)
filter=''
filterP='HAFAS\|PE-LIB-Version\|twe-\|vl-nps\|!!!\|amzn2.x86_64\|amzn2023.x86_64'
filterD='bibe_Plandaten\|BIBE_Plandaten\|adressdaten\|bhf-plan-2\|entry-pool-\|EPA3-\|k90\|KAM\|LTBW_R\|LTBW-ABO_R\|LTN_R\|pakmap\|poi-pool\|TWE_R\|ABOVERB_R\|TPOVERB_R\|FSTD_R\|!!!'

if [[ "$1" == *P* ]]; then
filter=$filterP
elif [[ "$1" == *D* ]]; then
filter=$filterD
elif [[ "$1" == *A* ]]; then
filter=$filterP'\|'$filterD
fi

shift
param=("$@")
skipEnvs=$(</var/jenkins_home/jenkinsDateneinsatzConfig/generated/envs_deactivated)
for param; do
  if [[ ${param} =~ ^(${skipEnvs})$ ]]; then
    echo skipping comparing psx${param}
  else
    newparams+=("$param")
  fi
done
set -- "${newparams[@]}"  # overwrites the original positional params

###how many occurance of data in each environment
once="$(expr $# \* 1)"
twice="$(expr $# \* 2)"
threex="$(expr $# \* 3)"
LTBW_FILTER="s/${twice} LTBW_R/OK LTBW_R/g"
LTBW_ABO_FILTER="s/${once} LTBW-ABO_R/OK LTBW-ABO_R/g"
LTN_FILTER="s/${threex} LTN_R/OK LTN_R/g"
PAKMAP_FILTER="s/${twice} pakmap_/OK pakmap_/g"
TWE_FILTER="s/${threex} TWE_R/OK TWE_R/g"
POI_FILTER="s/${twice} poi-pool-/OK poi-pool-/g"
BHF_FILTER="s/${twice} bhf-plan-2/OK bhf-plan-2/g"
ENTRY_FILTER="s/${twice} entry-pool-/OK entry-pool-/g"
ADR_FILTER="s/${twice} adressdaten-2/OK adressdaten-2/g"
ABOVBD_FILTER="s/${twice} ABOVERB_R/OK ABOVERB_R/g"
TPOVBD_FILTER="s/${once} TPOVERB_R/OK TPOVERB_R/g"
PLAN_FILTER="s/${threex} \([0-9_]*\)_BIBE_Plandaten_J2/OK \1_BIBE_Plandaten_J2/g"
REV_FILTER="s/${once} \([0-9_]*\)_BIBE_Plandaten_J25/OK \1_BIBE_Plandaten_J25/g"
PREV_FILTER="s/${threex} \([0-9_]*\)_bibe_Plandaten_J27/OK \1_bibe_Plandaten_J27/g"
STAMM_FILTER="s/${once} \(FSTD_R[2-4][0-9][0-1][0-9][0-3][0-9]_V[0-8][0-9][0-9]_2\)/OK \1/g"
################### MAIN #######################
{
  func_bibe_tpo_infos $@
}| sed -e 's/\"//g' -e 's/\.zip//g' -e 's/k90\_EKTR19 EPA3-\(.\)\_k90-0\([0-9]*\)\.20.../\1 V\2 k90_EKTR19 /' \
-e 's/\(EPA3-\)\(.\)\_1901001\_[0-9]*\_\(V[0-9]*\)/\2 \3 k90_EKTR19 /' -e 's/\(EPA3-\)\(.\)\_2901001\_[0-9]*\_\(V[0-9]*\)/\2 \3 k90_EKTR29 /' \
-e 's/\(EPA3-\)\(.\)\_1901000\_[0-9]*\_\(V[0-9]*\)/KAM \3 \2/' -e 's/\.tar\.bz2//g' -e 's/processes running:/pr_run/g' \
-e 's/pr_run 0/=============== !!! NO PROCESS RUNNING !!! ===============/g' | grep $filter | sort -d -s | uniq --count \
| sed  -e 's/[0-9]* KAM /- KAM /g' \
-e 's/'$twice' \(.*\).amzn2023.x86_64/OK \1.amzn2023.x86_64/g' -e 's/'$once' HAFAS/OK HAFAS/g' -e 's/'$once' $PEInfo: PE-LIB-Version 2/OK $PEInfo: PE-LIB-Version 2/g' \
-e 's/'$once' twe-20/OK twe-20/g' -e 's/'$once' vl-nps-20/OK vl-nps-20/g' \
-e "$ADR_FILTER" -e "$BHF_FILTER" -e "$ENTRY_FILTER" -e "$LTN_FILTER" \
-e "$LTBW_FILTER" -e "$LTBW_ABO_FILTER" -e "$PAKMAP_FILTER" -e "$TWE_FILTER" -e "$POI_FILTER" \
-e "$ABOVBD_FILTER" -e "$TPOVBD_FILTER" -e "$PLAN_FILTER" -e "$REV_FILTER" -e "$PREV_FILTER" -e "$STAMM_FILTER" \
| sed 's/^[ \t]*//;s/[ \t]*$//' | sort -b -d
func_live_check $@
