#!groovy
@Library('jenkins') _

def configurationMap = jsConfigurationGroovy.configurationMap()
def customParamList = jsConfigurationGroovy.parameters(configurationMap)

properties([parameters(customParamList), jenkinsOps.rebuildSettings()])
pipeline {
    agent { label jenkinsOps.defaultAgentLabel() }
    environment {
        CONFIG_PATH = "/var/jenkins_home/jenkinsDateneinsatzConfig/Configuration.groovy"
        // CONFIG_PATH = "/var/jenkins_home/jenkinsDateneinsatzConfig/Configuration_test.groovy"
    }

    stages {
        stage('POPULATE CONFIGMAP') {
            when {
                expression { !params.dryRun }
            }
            steps {
                script { jsConfigurationGroovy.populateConfigMap(configurationMap, params) }
            }
        }

        stage('PARSE CURRENT CONFIG') {
            when {
                expression { !params.dryRun }
            }
            steps {
                script { jsConfigurationGroovy.appendConfigDescription(env.CONFIG_PATH, 'Old Configuration.groovy:') }
            }
        }

        stage('CREATE CONFIG BACKUP') {
            when {
                expression { !params.dryRun && params.createBackup }
            }
            steps {
                script { jsConfigurationGroovy.backupConfig(env.CONFIG_PATH, env.BUILD_NUMBER, params.clearPreviouslycreatedBackups) }
            }
        }

        stage('CHANGE CONFIG AND GENERATE FILES') {
            when {
                expression { !params.dryRun }
            }
            steps {
                script { jsConfigurationGroovy.applyConfiguration(configurationMap, env.CONFIG_PATH) }
            }
        }

        stage('PARSE NEW CONFIG') {
            when {
                expression { !params.dryRun }
            }
            steps {
                script { jsConfigurationGroovy.appendConfigDescription(env.CONFIG_PATH, '\nNEW Configuration.groovy:', true) }
            }
        }
    }
}
