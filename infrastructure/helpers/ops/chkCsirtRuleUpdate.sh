#!/bin/bash

#bitte auf bastion unter persönlichen User ausführen
#script prüft ob auf allen psx instanzen im der root crontab ein update der csirt-Rules vorhanden ist
#falls nicht wird es eingefügt

#IP's ermitteln
IPS=$(aws ec2 describe-instances --filters Name=tag:Name,Values=*psx* Name=instance-state-name,Values=running  --query 'Reservations[*].Instances[*].PrivateIpAddress' --output text --region=eu-central-1)

#IPS="10.105.37.75"

for IP in $IPS
do
ssh -oStrictHostKeyChecking=no -t -t ${IP} <<-'ENDSSH'
sudo rootshell <<-'END2'
grep csirt_all_current.rules /var/spool/cron/root
if [ $? -ne 0 ]; then
        echo -e "\033[41m kein Eintrag in Crontab vorhanden add ...\033[0m."
        echo "0 2 * * * rm -f /etc/audit/rules.d/* && aws s3 --region eu-central-1 cp s3://zeroonezero-securityhub/Linux\ Security/auditd/master/src/csirt_all_current.rules /etc/audit/rules.d/csirt_all_current.rules && /sbin/service auditd restart >/dev/null 2>&1" >> /var/spool/cron/root
else
    #prüfen ob der richte Restart Befehl benutzt wird
    grep /sbin/service /var/spool/cron/root
        if [ $? -ne 0 ]; then
                echo -e "\033[41m Falscher restart Eintrag in Crontab vorhanden ...\033[0m."
                sed -i '/csirt_all_current/d' /var/spool/cron/root
                echo "0 2 * * * rm -f /etc/audit/rules.d/* && aws s3 --region eu-central-1 cp s3://zeroonezero-securityhub/Linux\ Security/auditd/master/src/csirt_all_current.rules /etc/audit/rules.d/csirt_all_current.rules && /sbin/service auditd restart >/dev/null 2>&1" >> /var/spool/cron/root
        else
                echo -e "\033[42m alles ok ...\033[0m."
        fi
fi
exit
END2
exit
ENDSSH
echo -e "\033[46m ${IP} \033[0m."
done
