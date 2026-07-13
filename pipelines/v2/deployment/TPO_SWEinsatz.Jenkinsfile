#!groovy
@Library('jenkins') _

def stageParamsMap = jsDataDeployment.psxStageParams()
def customParamList = jsSoftwareDeployment.tpoParameters(stageParamsMap)

properties([parameters(customParamList), jenkinsOps.rebuildSettings()])
pipeline {
    agent { label jenkinsOps.defaultAgentLabel() }

    stages {
        stage('SW S3SYNC') {
            when {
                expression { params.SW_S3Sync == true }
            }
            steps {
                script { jsSoftwareDeployment.syncTpoSoftware(params, WORKSPACE) }
            }
        }

        stage('UPDATE KM VERSION') {
            steps {
                script { jsSoftwareDeployment.updateTpoKmVersion(stageParamsMap, params) }
            }
        }

        stage('DIRECT SW INSTALL') {
            steps {
                script { jsSoftwareDeployment.installTpoSoftware(stageParamsMap, params) }
            }
        }

        stage('DEPLOY LATEST BASE IMAGE AL2023') {
            steps {
                script { jsSoftwareDeployment.deployTpoBaseImage(stageParamsMap, params) }
            }
        }

        stage('WAIT FOR STACK UPDATE COMPLETE') {
            steps {
                script { jsSoftwareDeployment.waitForTpoStackUpdates(stageParamsMap, params) }
            }
        }

        stage('COMPARING ENVs') {
            when {
                expression { params.compare_data }
            }
            steps {
                script { env.DESC = jsSoftwareDeployment.compareBibeTpoSoftware(stageParamsMap, params) }
            }
        }
    }

    post {
        always {
            script {
                currentBuild.description = "${params.RELEASE} ${params.KM_VERSION}"
                jsSoftwareDeployment.addTpoPostBadges(stageParamsMap, params)
            }
        }
    }
}
