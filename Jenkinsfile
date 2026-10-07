pipeline {
    agent any
    options { timestamps() }
    stages {
        stage('Validate repository layout') {
            steps {
                sh '''
                    test -d pipelines/v2/deployment
                    test -d pipelines/v2/configuration
                    test -d pipelines/legacy/deployment
                    test -d pipelines/legacy/configuration
                    test -d infrastructure/helpers/deployment
                    test -d infrastructure/helpers/ops
                    test -d infrastructure/helpers/python
                    test -d infrastructure/ansible
                    test -d config/pman
                    test -d config/update-stack
                    test -d legacy/obsolete
                    test -d docs
                    test ! -d src
                    test ! -d vars
                    test ! -d resources
                    test ! -d test
                    test ! -f config/jenkins-configuration-builder.groovy
                    test ! -f config/jenkins-configuration.example.groovy
                '''
            }
        }
        stage('Validate canonical paths') {
            steps {
                sh '''
                    test -f pipelines/v2/deployment/BIBE_SWEinsatz.Jenkinsfile
                    test -f pipelines/v2/deployment/BIBE_TPO_DataDeployment.Jenkinsfile
                    test -f pipelines/v2/deployment/TPO_SWEinsatz.Jenkinsfile
                    test -f pipelines/v2/configuration/modifyConfigurationGroovy.Jenkinsfile
                    test -f pipelines/legacy/deployment/BIBE_SWEinsatz.Jenkinsfile
                    test -f infrastructure/helpers/deployment/BIBE_createSnapshot.sh
                    test -f infrastructure/helpers/python/create-snapshot.py
                    test -f infrastructure/helpers/python/pman.py
                    test -f config/update-stack/update-stack.py
                    test -z "$(find . -type l -print -quit)"
                '''
            }
        }
        stage('Validate pipeline layering') {
            steps {
                sh '''
                    test "$(find pipelines/legacy -type f | wc -l)" = "$(find pipelines/v2 -type f | wc -l)"
                    grep -R "@Library('jenkins') _" pipelines/v2 >/dev/null
                    ! grep -R "Delegate to legacy\|triggerJob('BIBE_SWDeployment\|triggerJob('DataDeployment\|triggerJob('TPO_SWDeployment\|triggerJob('onOffEnvinroment" pipelines/v2
                    ! grep -R "sshagent(\|7f075ad2\|dir(\"infrastructure/helpers/deployment\")\|dir(\"config/pman\")\|dir(\"config/update-stack\")" pipelines/v2
                '''
            }
        }
        stage('Validate whitespace') {
            steps {
                sh 'git diff --check'
            }
        }
    }
}
