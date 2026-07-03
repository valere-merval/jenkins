#!groovy
@Library('jenkins') _
properties([
    parameters([
        separator(name: "MAIN_PARAM", sectionHeader: "Upgrade Base Image", separatorStyle: "border-width: 3px", sectionHeaderStyle: "background-color: #90ee90"),
        booleanParam(name: 'latest_BI', defaultValue: true, description: 'Toggle this on if you want to deploy latest base image'),
        separator(name: "SECOND_PARAM", sectionHeader: "Upgrade Jenkins LTS Version - OPTIONAL", separatorStyle: "border-width: 3px", sectionHeaderStyle: "background-color: #90ee90"),
        string(name: 'Version',  defaultValue: '', description: '!!! OPTIONAL !!! ex. 2.277.2 - the LTS Core Version to update, leave it empty to skip Jenkins Core Upgrade'),
    ]), [$class: 'RebuildSettings', autoRebuild: false, rebuildDisabled: false]])
pipeline {
    agent { label jenkinsOps.defaultAgentLabel() }

    stages {
        stage('Base Image Update') {
            when {
                expression { params.latest_BI }
            }
            steps{
                jenkinsOps.withUpdateStack {
                    script {
                    sh """
                        aws ec2 describe-images --filters Name=name,Values=dbv-amzn2-base* --owners self --query 'sort_by(Images, &CreationDate)[-1].Name'
                        echo "AMI: `aws ec2 describe-images --filters Name=name,Values=dbv-amzn2-base* --owners self --query 'sort_by(Images, &CreationDate)[-1].ImageId' --output text`" >> hdm-psx.cfg
                    """
                    }
                }
            }
        }

        stage('JENKINS VERSION Check') {
            when {
                expression { params.Version != '' && !(params.Version ==~ /^[2-4]\.[0-9]+\.[1-5]$/)}
            }
            steps{
                error("Jenkins Version is not as expected, if it is valid, please fix Pipeline script REGEX")
            }
        }

        stage('JENKINS Core Upgrade') {
            when {
                expression { params.Version != '' }
            }
            steps{
                jenkinsOps.withUpdateStack {
                    script {
                        sh "echo \"JenkinsDownloadUrl: https://bahnhub.tech.rz.db.de/artifactory/jenkins-rpm-remote/jenkins-${params.Version}-1.1.noarch.rpm\" >> hdm-psx.cfg"
                    }
                }
            }
        }

        stage('Update CLFS') {
            when {
                expression { params.latest_BI || params.Version == '' }
            }
            steps{
                jenkinsOps.withUpdateStack {
                    script {
                        sh '''
                        cat hdm-psx.cfg
                        ./update-stack.py hdm-psx.cfg
                        '''
                    }
                }
            }
        }

        stage('WAIT FOR STACK UPDATE COMPLETES') {
            when {
                expression { params.latest_BI || params.Version == '' }
            }
            steps{
                wait_4_stack_update_complete()
            }
        }
    }

    post {
        always {
            script {
                currentBuild.description = "BI Update: ${latest_BI}; Jenkins LTS: ${Version}"
            }
        }
    }
}

def wait_4_stack_update_complete() {
    sh "aws cloudformation wait stack-update-complete --stack-name nvs-psx-hdm"
    sh """
    sleep 600 || true
        if [[ `aws cloudformation describe-stack-events --stack-name nvs-psx-hdm --max-items 1 --output text --query 'StackEvents[*].ResourceStatus' | grep 'UPDATE_COMPLETE'` == 'UPDATE_COMPLETE' ]]
        then
            echo "stack upddate succeed"
        else
            echo "ERROR: expected status UPDATE_COMPLETE not recognized"
            exit 11
        fi
    """
}