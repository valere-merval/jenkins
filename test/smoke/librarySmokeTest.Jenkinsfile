@Library('jenkins') _

// Smoke test runnable on the real Jenkins instance.
// Loads the shared library and calls one NON-DESTRUCTIVE step of each facade
// to prove that the vars -> src refactor loads and delegates correctly.
// No deployment, no SSH, no external side effects.

pipeline {
    agent { label jenkinsOps.defaultAgentLabel() }

    options {
        timeout(time: 10, unit: 'MINUTES')
        disableConcurrentBuilds()
    }

    stages {
        stage('jenkinsOps') {
            steps {
                script {
                    echo "defaultAgentLabel = ${jenkinsOps.defaultAgentLabel()}"
                    echo "dataTypeName(EKTR_19) = ${jenkinsOps.dataTypeName('EKTR_19')}"
                    assert jenkinsOps.dataTypeName('EKTR_19') == 'VL_NPS_EBPB'
                }
            }
        }
        stage('jsDataDeployment') {
            steps {
                script {
                    def stageParams = jsDataDeployment.psxStageParams()
                    echo "psxStageParams keys = ${stageParams.keySet()}"
                    assert jsDataDeployment.bibeTpoPmanDataMap() instanceof Map
                }
            }
        }
        stage('jsSoftwareDeployment') {
            steps {
                script {
                    def params = jsSoftwareDeployment.tpoParameters(jsDataDeployment.psxStageParams())
                    echo "tpoParameters count = ${params.size()}"
                    assert params instanceof List
                }
            }
        }
        stage('jsEnvironmentControl') {
            steps {
                script {
                    def p = jsEnvironmentControl.parameters(jsEnvironmentControl.stageParams())
                    echo "environment parameters count = ${p.size()}"
                    assert p instanceof List
                }
            }
        }
        stage('jsConfigurationGroovy') {
            steps {
                script {
                    def map = jsConfigurationGroovy.configurationMap()
                    echo "configurationMap sections = ${map.keySet()}"
                    assert map instanceof Map
                }
            }
        }
    }

    post {
        success { echo 'SMOKE OK: shared library facades load and delegate on Jenkins.' }
        failure { echo 'SMOKE FAILED: check the stage that threw above.' }
    }
}
