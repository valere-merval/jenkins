#!/bin/bash
set -e
vr_setting=$1
psxEnv=$2

# remove given first (no effect if there is no record in list)
sed -i -e 's/envs_preview="\(x[hijklmnq|]*\)|'$psxEnv'\([hijklmnq|]*\)"/envs_preview="\1\2"/g' /var/jenkins_home/jenkinsDateneinsatzConfig/Configuration.groovy
if [[ $vr_setting == 'Vorschau' ]]; then
  # add env if env was set for preview recently
  sed -i -e 's/envs_preview="\(x[hijklmnq|]*\)"/envs_preview="\1|'$psxEnv'"/g' /var/jenkins_home/jenkinsDateneinsatzConfig/Configuration.groovy
fi
cd /var/jenkins_home/jenkinsDateneinsatzConfig
./BuilderJenkinsConfiguration.groovy