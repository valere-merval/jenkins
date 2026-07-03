#!groovy
import org.jenkinsci.plugins.pipeline.modeldefinition.Utils

def stageParamsMap = [
    h: [ action: '-' ],
    i: [ action: '-' ],
    j: [ action: '-' ],
    k: [ action: '-' ],
    l: [ action: '-' ],
    m: [ action: '-' ],
    q: [ action: '-' ]
]

def customParamList = [
    separator(name: "Umgebung_Auswahl", sectionHeader: "Umgebung für Action", separatorStyle: "border-width: 3px", sectionHeaderStyle: "background-color: #90ee90"),
]

stageParamsMap.each { key, value ->
    customParamList.add(choice(name: "env_${key}", choices: ['-', 'on', 'off'], description: "Toggle this on if you want to control ${key} environemnt"))
}


properties([parameters(customParamList), [$class: 'RebuildSettings', autoRebuild: false, rebuildDisabled: false]])
pipeline {
    agent { label 'master' }

    stages {
        stage('PREPARE CONFIG') {
            steps {
                script {
                    stageParamsMap.each { key, value ->
                        def action = params["env_$key"]
                        stage(key, action != '-', {
                            if (action == 'on') {
                                value.action = 1
                            } else if (action == 'off'){
                                value.action = 0
                            } else {
                                error("undefined chocie: ${action}")
                            }
                        })
                    }
                }
            }
        }

        stage('ENALE/DISABLE ENVIROMENT') {
            steps {
                script {
                    def branches = [:]
                    stageParamsMap.each { key, value ->
                        branches["BIBE $key"] = { stage("BIBE $key", value.action != '-', {
                                dir("deployment") {
                                    sh "./onOffEnvinronment_BIBE_clfsUpdate.sh \'${value.action}\' \'${key}\'"
                                }
                        }) }
                        branches["TPO $key"] = { stage("TPO $key", value.action != '-', {
                                dir("deployment") {
                                    sh "./onOffEnvinronment_TPO_clfsUpdate.sh \'${value.action}\' \'${key}\'"
                                }
                        }) }
                    }
                    parallel branches
                }
            }
        }
        stage('WAIT FOR STACK UPDATE COMPLETE') {
            steps {
                script {
                    stageParamsMap.each { key, value ->
                        stage("BIBE $key", value.action != '-', {
                                dir("deployment") {
                                    sh "aws cloudformation wait stack-update-complete --stack-name nvs-psx${key}-bibe"
                                }
                        })
                        stage("TPO $key", value.action != '-', {
                                dir("deployment") {
                                    sh "aws cloudformation wait stack-update-complete --stack-name tpo-psx${key}-appsrv"
                                }
                        })
                    }
                }
            }
        }
        stage('UPDATE CONFIG') {
            steps {
                script {
                    stageParamsMap.each { key, value ->
                        stage(key, value.action != '-', {
                                dir("deployment") {
                                    sh "./onOffEnvinronment_updateConfig.sh \'${value.action}\' \'${key}\'"
                                }
                        })
                    }
                }
            }
        }
    }

    post {
        always {
            script {
                currentBuild.description = "======================================================\n\nRELEASE CONFIGURATION:\n\n" + readConfigfile()
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
                    if (value.action != '-') {
                    //     if (value.action == 1) {
                    //         // manager.addShortText("${key}", "green", "white", "2px", "green");
                    //         environmentsList.add(key.toString().concat(" -> on"));
                    //     } else {
                    //         // manager.addShortText("${key}", "red", "yellow", "2px", "red");
                    //         environmentsList.add(key.toString().concat(" -> off"));
                    //     }
                        environmentsList.add(key.toString().concat(" -> " + value.action.toString()));
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

def readConfigfile() {
    String response = sh( script: "cat /var/jenkins_home/jenkinsDateneinsatzConfig/Configuration.groovy", returnStdout: true)
    return response
}

def stage(name, execute, block) {
    return stage(name, execute ? block : {
        echo 'Stage "' + name + '" skipped due to when conditional.'
        Utils.markStageSkippedForConditional(STAGE_NAME)
    })
}