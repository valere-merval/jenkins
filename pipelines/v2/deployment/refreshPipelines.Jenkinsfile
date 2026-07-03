#!groovy
@Library('jenkins') _
pipeline {
    agent { label jenkinsOps.defaultAgentLabel() }
/*     parameters {
        booleanParam(name: 'DataDeployment', defaultValue: true, description: 'Toggle this on if you want sync SW archive data into S3')
        booleanParam(name: 'BIBE_SWDeployment', defaultValue: true, description: 'Toggle this on if you want to update version file')
        booleanParam(name: 'TPO_SWDeployment', defaultValue: true, description: 'Toggle this on if you want to install update')
    } */

    stages {
        stage('REFRESH') {
            parallel {
        stage('compare_tpo_bibe') {
            steps{
                build job: 'compare_tpo_bibe', parameters: [
                    booleanParam(name: 'env_h', value: '-') ,
                    booleanParam(name: 'env_i', value: '-') ,
                    booleanParam(name: 'env_j', value: '-') ,
                    booleanParam(name: 'env_k', value: '-') ,
                    booleanParam(name: 'env_l', value: '-') ,
                    booleanParam(name: 'env_m', value: '-') ,
                    booleanParam(name: 'env_n', value: '-') ,
                    booleanParam(name: 'env_q', value: '-') ]
                build job: 'compare_tpo_bibe', parameters: [
                    booleanParam(name: 'env_h', value: '-') ,
                    booleanParam(name: 'env_i', value: '-') ,
                    booleanParam(name: 'env_j', value: '-') ,
                    booleanParam(name: 'env_k', value: '-') ,
                    booleanParam(name: 'env_l', value: '-') ,
                    booleanParam(name: 'env_m', value: '-') ,
                    booleanParam(name: 'env_n', value: '-') ,
                    booleanParam(name: 'env_q', value: '-') ]
            }
        }
        stage('onOffEnvinroment') {
            steps{
                build job: 'onOffEnvinroment'
                build job: 'onOffEnvinroment'
            }
        }
        stage('DataDeployment') {
            steps{
                build job: 'DataDeployment', parameters: [
                    booleanParam(name: 'pman_explicit', value: false) ,
                    booleanParam(name: 'tpo_data_deployment', value: false) ,
                    booleanParam(name: 'bibe_data_deployment', value: false) ,
                    booleanParam(name: 'compare_data', value: false) ]
                build job: 'DataDeployment', parameters: [
                    booleanParam(name: 'pman_explicit', value: false) ,
                    booleanParam(name: 'tpo_data_deployment', value: false) ,
                    booleanParam(name: 'bibe_data_deployment', value: false) ,
                    booleanParam(name: 'compare_data', value: false) ]
            }
        }
        stage('tDataDeployment') {
            steps{
                build job: 'test/tDataDeployment', parameters: [
                    booleanParam(name: 'pman_explicit', value: false) ,
                    booleanParam(name: 'tpo_data_deployment', value: false) ,
                    booleanParam(name: 'bibe_data_deployment', value: false) ,
                    booleanParam(name: 'compare_data', value: false) ]
                build job: 'test/tDataDeployment', parameters: [
                    booleanParam(name: 'pman_explicit', value: false) ,
                    booleanParam(name: 'tpo_data_deployment', value: false) ,
                    booleanParam(name: 'bibe_data_deployment', value: false) ,
                    booleanParam(name: 'compare_data', value: false) ]
            }
        }
        stage('BIBE_SWDeployment') {
            steps{
                build job: 'BIBE_SWDeployment', parameters: [
                    booleanParam(name: 'SW_S3Sync', value: false) ,
                    booleanParam(name: 'createSnapshot', value: false) ,
                    booleanParam(name: 'DEPLOY_LATEST_SNAPSHOT', value: false) ,
                    booleanParam(name: 'compare_data', value: false) ]
                build job: 'BIBE_SWDeployment', parameters: [
                    booleanParam(name: 'SW_S3Sync', value: false) ,
                    booleanParam(name: 'createSnapshot', value: false) ,
                    booleanParam(name: 'DEPLOY_LATEST_SNAPSHOT', value: false) ,
                    booleanParam(name: 'compare_data', value: false) ]
            }
        }
        stage('tBIBE_SWDeployment') {
            steps{
                build job: 'test/tBIBE_SWDeployment', parameters: [
                    booleanParam(name: 'SW_S3Sync', value: false) ,
                    booleanParam(name: 'createSnapshot', value: false) ,
                    booleanParam(name: 'DEPLOY_LATEST_SNAPSHOT', value: false) ,
                    booleanParam(name: 'compare_data', value: false) ]
                build job: 'test/tBIBE_SWDeployment', parameters: [
                    booleanParam(name: 'SW_S3Sync', value: false) ,
                    booleanParam(name: 'createSnapshot', value: false) ,
                    booleanParam(name: 'DEPLOY_LATEST_SNAPSHOT', value: false) ,
                    booleanParam(name: 'compare_data', value: false) ]
            }
        }
        stage('TPO_SWDeployment') {
            steps{
                build job: 'TPO_SWDeployment', parameters: [
                    booleanParam(name: 'SW_S3Sync', value: false) ,
                    booleanParam(name: 'UPDATE_KM_VERSION', value: false) ,
                    booleanParam(name: 'DIRECT_SW_INSTALL', value: false) ,
                    booleanParam(name: 'DEPLOY_NEW_BASE_IMAGE', value: false) ,
                    booleanParam(name: 'compare_data', value: false) ]
                build job: 'TPO_SWDeployment', parameters: [
                    booleanParam(name: 'SW_S3Sync', value: false) ,
                    booleanParam(name: 'UPDATE_KM_VERSION', value: false) ,
                    booleanParam(name: 'DIRECT_SW_INSTALL', value: false) ,
                    booleanParam(name: 'DEPLOY_NEW_BASE_IMAGE', value: false) ,
                    booleanParam(name: 'compare_data', value: false) ]
            }
        }
        stage('tTPO_SWDeployment') {
            steps{
                build job: 'test/tTPO_SWDeployment', parameters: [
                    booleanParam(name: 'SW_S3Sync', value: false) ,
                    booleanParam(name: 'UPDATE_KM_VERSION', value: false) ,
                    booleanParam(name: 'DIRECT_SW_INSTALL', value: false) ,
                    booleanParam(name: 'DEPLOY_NEW_BASE_IMAGE', value: false) ,
                    booleanParam(name: 'compare_data', value: false) ]
                build job: 'test/tTPO_SWDeployment', parameters: [
                    booleanParam(name: 'SW_S3Sync', value: false) ,
                    booleanParam(name: 'UPDATE_KM_VERSION', value: false) ,
                    booleanParam(name: 'DIRECT_SW_INSTALL', value: false) ,
                    booleanParam(name: 'DEPLOY_NEW_BASE_IMAGE', value: false) ,
                    booleanParam(name: 'compare_data', value: false) ]
            }
        }
            }
        }
    }
}