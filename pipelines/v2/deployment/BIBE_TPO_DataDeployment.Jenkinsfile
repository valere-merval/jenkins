#!groovy
@Library('jenkins') _

// Used Scripts & Files:
// ------------------------------------------------------------------
// /var/jenkins_home/jenkinsDateneinsatzConfig/Configuration.groovy
// /var/jenkins_home/jenkinsDateneinsatzConfig/generated/*
// pman.py
// terminate_psx_bibe.sh
// datenEinsatz_resetBIBE_with_playbook.sh
// terminate_psx_tpo.sh
// datenEinsatz_resetTPO.sh
// compare_bibe_tpo.sh

def stageParamsMap = jsDataDeployment.psxStageParams()
def customParamList = jsDataDeployment.bibeTpoParameters(stageParamsMap)
def pmanDatenMap = jsDataDeployment.bibeTpoPmanDataMap()

properties([parameters(customParamList), [$class: 'RebuildSettings', autoRebuild: false, rebuildDisabled: false]])
pipeline {
    agent { label jenkinsOps.defaultAgentLabel() }

    stages {

        stage('POPULATE DATAPOOLS FOR PMAN') {
            steps {
                script {
                    def branches = [:]
                    pmanDatenMap.each { dataSet, dataTypes ->
                        branches[dataSet] = { jenkinsOps.conditionalStage("$dataSet", params.pman, {
                            params.each { key, value ->
                                // echo "Key: ${key} - Value: ${value}"
                                if (key in dataTypes.keySet()) {
                                    dataTypes[key] = value
                                }
                            }
                            // Just for outputting infos:
                            currentBuild.description = "SELECTED DATA:\n\n"
                            dataTypes.each { dataType, data ->
                                def firstDataTypesEntryName = dataTypes.entrySet().iterator().next().key
                                def firstDataTypesEntryValue = dataTypes.entrySet().iterator().next().value
                                if (firstDataTypesEntryValue == '') {
                                    if (firstDataTypesEntryName == dataType) {
                                        addWarningBadge(text: "${firstDataTypesEntryName} skipped")
                                    } else if (data != '') {
                                        currentBuild.description += "${firstDataTypesEntryName} - ${dataType} : ${data} -> SKIPPED\n"
                                    }
                                } else if (data != '') {
                                    echo "DataType: ${dataType} - Data: ${data}"
                                    currentBuild.description += "${firstDataTypesEntryName} - ${dataType} : ${data}\n"
                                }
                            }
                        })}
                    }
                    parallel branches
                }
            }
        }

        stage('PMAN') {
            steps {
                script {
                    def branches = [:]
                    stageParamsMap.each { key, value ->
                        branches[key] = { jenkinsOps.conditionalStage("$key", params["env_$key"]  == 'enable' && params.pman, {
                            catchError(buildResult: 'UNSTABLE', stageResult: 'FAILURE') {
                                jenkinsOps.withPman {
                                pmanDatenMap.each { dataSet, dataTypes ->
                                    def firstDataTypesEntryValue = dataTypes.entrySet().iterator().next().value
                                    if (firstDataTypesEntryValue != '') {
                                        echo "FirstDataTypesEntryValue: ${firstDataTypesEntryValue}"
                                        dataTypes.each { dataType, data ->
                                            dataType = jenkinsOps.dataTypeName(dataType)
                                                if (data == 'latest' && data != firstDataTypesEntryValue) {
                                                    // echo "./pman.py --datatype \'${dataType}\' --latest \'${firstDataTypesEntryValue}${key}.yml\'"
                                                    sh "./pman.py --datatype \'${dataType}\' --latest \'${firstDataTypesEntryValue}${key}.yml\'"
                                                    sleep 1
                                                } else if (data != '' && data != firstDataTypesEntryValue) {
                                                    // echo "./pman.py --datatype \'${dataType}\' --pkgname \'${data}\' \'${firstDataTypesEntryValue}${key}.yml\'"
                                                    sh "./pman.py --datatype \'${dataType}\' --pkgname \'${data}\' \'${firstDataTypesEntryValue}${key}.yml\'"
                                                    sleep 1
                                                    // // ./pman.py --datatype connection-preview --pkgname 123_001_bibe_Plandaten_J25.zip hafaspools-auskunft-tst.yml
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        })}
                    }
                    parallel branches
                }
            }
        }

        // stage('DATA DEPLOYMENT') {
        //     steps {
        //         script {
        //             if (params.terminate_instances) { addInfoBadge(text: "Terminate Instances"); }
        //             def branches = [:]
        //             stageParamsMap.each { key, value ->
        //                 branches["$key(b)"] = { stage("bibe $key", params["env_$key"]  == 'enable' && params.bibe_data_deployment, {
        //                     if (params.terminate_instances) {
        //                         sh "./terminate_psx_bibe.sh \'${key}\'"
        //                         sleep(time:10,unit:"MINUTES")
        //                     } else {
        //                         jenkinsOps.runDeploymentShell("./datenEinsatz_resetBIBE_with_playbook.sh \'${key}\'")
        //                     }
        //                 })}
        //                 branches["$key(t)"] = { stage("tpo $key", params["env_$key"]  == 'enable' && params.tpo_data_deployment, {
        //                     if (params.terminate_instances) {
        //                         sh "./terminate_psx_tpo.sh \'${key}\'"
        //                         sleep(time:10,unit:"MINUTES")
        //                     } else {
        //                         jenkinsOps.runDeploymentShell("./datenEinsatz_resetTPO.sh \'${key}\'")
        //                     }
        //                 })}
        //             }
        //             parallel branches
        //         }
        //     }
        // }

        stage('DATA DEPLOYMENT') {
            when {
                    expression {
                    stageParamsMap.keySet().any { env ->
                        params["env_$env"] == 'enable' && jenkinsOps.isEnvironmentActive(env)
                    }
                }
            }
            steps {
                script {
                    def activeEnvironments = stageParamsMap.keySet().findAll { env ->
                        params["env_$env"] == 'enable' && jenkinsOps.isEnvironmentActive(env)
                    }

                    if (activeEnvironments.isEmpty()) {
                        addWarningBadge(text: "No active environments selected")
                    }

                    if (params.terminate_instances) {
                        addInfoBadge(text: "Terminate Instances");
                    }

                    def branches = [:]
                    stageParamsMap.keySet().each { key ->
                        def currentKey = key
                        def currentValue = params["env_$key"]
                        branches[key] = {
                            def subBranches = [:]
                            subBranches["BIBE ${currentKey}"] = { jenkinsOps.conditionalStage("BIBE ${currentKey}", currentValue == 'enable'
                                                                                              && jenkinsOps.isEnvironmentActive(currentKey)
                                                                                              && params.bibe_data_deployment, {
                                if (params.terminate_instances) {
                                    sh "./terminate_psx_bibe.sh \'${currentKey}\'"
                                    sleep(time:10,unit:"MINUTES")
                                } else {
                                    jenkinsOps.runDeploymentShell("./datenEinsatz_resetBIBE_with_playbook.sh \'${currentKey}\'")
                                }
                            })}
                            subBranches["TPO ${currentKey}"] = { jenkinsOps.conditionalStage("TPO ${currentKey}", currentValue == 'enable'
                                                                                            && jenkinsOps.isEnvironmentActive(currentKey)
                                                                                            && params.tpo_data_deployment, {
                                if (params.terminate_instances) {
                                    sh "./terminate_psx_tpo.sh \'${currentKey}\'"
                                    sleep(time:10,unit:"MINUTES")
                                } else {
                                    jenkinsOps.runDeploymentShell("./datenEinsatz_resetTPO.sh \'${currentKey}\'")
                                }
                            })}
                            parallel subBranches
                        }
                    }
                    parallel branches
                }
            }
        }

        stage('COMPARING ENVs') {
            when {
                expression {
                    params.compare_data &&
                    stageParamsMap.keySet().any { env ->
                        params["env_$env"] == 'enable' && jenkinsOps.isEnvironmentActive(env)
                    }
                }
            }
            steps{
                script {
                    env.DESC = ''
                    stageParamsMap.each { key, value ->
                        if (
                            params["env_$key"] == 'enable'
                            && jenkinsOps.isEnvironmentActive(key)
                        ) {
                            env.DESC="${env.DESC} $key"
                        }
                    }
                    catchError(buildResult: 'UNSTABLE', stageResult: 'FAILURE') {
                        jenkinsOps.runDeploymentShell("./compare_bibe_tpo.sh D ${DESC}")
                    }
                }
            }
        }

    }

    post {
        always {
            script {
                currentBuild.description += "\n\n======================================================\n\nRELEASE CONFIGURATION:\n\n" + jenkinsOps.readConfigFile()
                def buildUser = "unknown"
                wrap([$class: 'BuildUser']) {
                    try {
                        buildUser = BUILD_USER
                    } catch (e) {
                        echo "User not in scope, probably triggered from another job"
                    }
                }
                addBadge(text: buildUser.toString());
                def environmentsList = []
                stageParamsMap.each { key, value ->
                    if (
                        params["env_$key"] == 'enable'
                        && jenkinsOps.isEnvironmentActive(key)
                    ) {
                        environmentsList.add(key.toString());
                    }
                }
                if ( environmentsList.isEmpty() ) {
                    addWarningBadge(text: "No Environments chosen!");
                } else {
                    addBadge(text: environmentsList.toString());
                }
            }
        }
    }
}
