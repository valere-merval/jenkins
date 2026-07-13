#!groovy
@Library('jenkins') _

def stageParamsMap = jsEnvironmentControl.stageParams()
def customParamList = jsEnvironmentControl.parameters(stageParamsMap)
def configPath = '/var/jenkins_home/jenkinsDateneinsatzConfig/Configuration.groovy'

properties([parameters(customParamList), jenkinsOps.rebuildSettings()])
pipeline {
    agent { label jenkinsOps.defaultAgentLabel() }
    environment {
        PARENT_DIR = "${env.WORKSPACE}/config/update-stack/"
    }

    stages {
        stage('LOAD STACK PARAMETERS') {
            when {
                expression { !params.dryRun }
            }
            steps {
                script { jsEnvironmentControl.loadStackParameters(stageParamsMap, params, env.PARENT_DIR) }
            }
        }

        stage('PREPARE CONFIGURATION FILES') {
            when {
                expression { !params.dryRun }
            }
            steps {
                script { jsEnvironmentControl.prepareConfigurationFiles(stageParamsMap, params, env.PARENT_DIR, configPath) }
            }
        }

        stage('SET AMIs TO USE') {
            when {
                expression { !params.dryRun }
            }
            steps {
                script { jsEnvironmentControl.setAmisToUse(stageParamsMap, params, env.PARENT_DIR) }
            }
        }

        stage('ENABLE/DISABLE ENVIROMENT') {
            when {
                expression { !params.dryRun }
            }
            steps {
                script { jsEnvironmentControl.enableDisableEnvironment(stageParamsMap) }
            }
        }
    }

    post {
        always {
            script { jsEnvironmentControl.addPostInfo(stageParamsMap, configPath) }
        }
    }
}
