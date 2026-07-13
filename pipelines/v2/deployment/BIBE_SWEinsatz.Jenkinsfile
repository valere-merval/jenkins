#!/usr/bin/env groovy
@Library('jenkins') _

// Used Scripts & Files:
// -----------------------------------------------------------------------
// /var/jenkins_home/jenkinsDateneinsatzConfig/generated/RELEASE
// /share/SOFTWARE/pe/*
// /share/SOFTWARE/hafas/nvs/*
// /var/jenkins_home/jenkinsDateneinsatzConfig/generated/ENV_*_RELEASE
// BIBE_run_update_IM.sh
// BIBE_PE_S3Sync.sh
// BIBE_PE_CheckVersion.sh
// BIBE_PE_UpdateIM.sh
// BIBE_SERVER_S3Sync.sh
// BIBE_SERVER_CheckVersion.sh
// BIBE_SERVER_UpdateIM.sh
// BIBE_createSnapshot.sh
// BIBE_check_PE_SERVER_Version.sh
// BIBE_deploy_LatestAMI_withJenkins.sh
// compare_bibe_tpo.sh

def stageParamsMap = jsDataDeployment.psxStageParams()
def customParamList = jsSoftwareDeployment.bibeParameters(stageParamsMap)
def imageMaster = ''
def commentHelper = ''

properties([parameters(customParamList), jenkinsOps.rebuildSettings()])
pipeline {
    agent { label jenkinsOps.defaultAgentLabel() }

    stages {
        stage('set imageMaster Parameter') {
            steps {
                script {
                    imageMaster = jsSoftwareDeployment.bibeImageMaster(params.RELEASE)
                    echo "${params.RELEASE.drop(2).take(4)}"
                    echo "${imageMaster}"
                }
            }
        }

        stage('PREREQs') {
            parallel {
                stage('setting comment') {
                    steps {
                        script {
                            commentHelper = jsSoftwareDeployment.bibeComment(params)
                            echo "${commentHelper}"
                        }
                    }
                }
                stage('run+update image_master') {
                    when {
                        expression { params.createSnapshot || params.PE || params.SERVER || params.kernel_update }
                    }
                    steps {
                        script { jsSoftwareDeployment.runBibeImageMaster(imageMaster) }
                    }
                }
            }
        }

        stage('SW S3SYNC PE') {
            when {
                expression { params.SW_S3Sync && params.PE }
            }
            steps {
                script { jsSoftwareDeployment.syncBibePe(params.RELEASE) }
            }
        }

        stage('CHECK PE VERSION') {
            when {
                expression { params.PE }
            }
            steps {
                script { jsSoftwareDeployment.checkBibePeVersion(params.RELEASE, params.PE_Subversion, imageMaster) }
            }
        }

        stage('IMAGEMASTER INSTALL PE') {
            when {
                expression { params.PE }
            }
            steps {
                script { jsSoftwareDeployment.installBibePe(params.RELEASE, params.PE_Subversion, imageMaster) }
            }
        }

        stage('SW S3SYNC SERVER') {
            when {
                expression { params.SW_S3Sync && params.SERVER }
            }
            steps {
                script { jsSoftwareDeployment.syncBibeServer(params.current_server_release) }
            }
        }

        stage('CHECK SERVER VERSION') {
            when {
                expression { params.SERVER }
            }
            steps {
                script { jsSoftwareDeployment.checkBibeServerVersion(imageMaster, params.SERVER_VERSION) }
            }
        }

        stage('IMAGEMASTER INSTALL SERVER') {
            when {
                expression { params.SERVER }
            }
            steps {
                script { jsSoftwareDeployment.installBibeServer(imageMaster, params.SERVER_VERSION) }
            }
        }

        stage('CREATE SNAPSHOT') {
            when {
                expression { params.createSnapshot }
            }
            steps {
                script { jsSoftwareDeployment.createBibeSnapshot(imageMaster, commentHelper, params.KM) }
            }
        }

        stage('DEPLOY LATEST AMI SNAPSHOT') {
            steps {
                script { jsSoftwareDeployment.deployBibeLatestSnapshot(stageParamsMap, params, imageMaster) }
            }
        }

        stage('WAIT FOR STACK UPDATE COMPLETE') {
            steps {
                script { jsSoftwareDeployment.waitForBibeStackUpdates(stageParamsMap, params) }
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
                currentBuild.description = "Release: ${params.RELEASE}\n KM: ${params.KM}\n Kommentar: ${commentHelper}"
                jsSoftwareDeployment.addBibePostBadges(stageParamsMap, params)
            }
        }
    }
}
