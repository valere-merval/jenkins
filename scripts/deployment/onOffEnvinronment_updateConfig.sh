#!/bin/bash
set -e
action=$1
psxEnv=$2

# remove given first (no effect if there is no record in list)
sed -i -e 's/envs_deactivated="\(x[hijklmnq|]*\)|'$psxEnv'\([hijklmnq|]*\)"/envs_deactivated="\1\2"/g' /var/jenkins_home/jenkinsDateneinsatzConfig/Configuration.groovy
if [[ $action == 0 ]]; then
  # add env if env was deactivated recently
  sed -i -e 's/envs_deactivated="\(x[hijklmnq|]*\)"/envs_deactivated="\1|'$psxEnv'"/g' /var/jenkins_home/jenkinsDateneinsatzConfig/Configuration.groovy
fi
cd /var/jenkins_home/jenkinsDateneinsatzConfig
./BuilderJenkinsConfiguration.groovy