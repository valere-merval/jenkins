#!groovy
@Library('jenkins') _
import org.jenkinsci.plugins.pipeline.modeldefinition.Utils
def stageParamsMap = [
    h: [  ],
    i: [  ],
    j: [  ],
    k: [  ],
    l: [  ],
    m: [  ],
    q: [  ]
    ]

def customParamList = [
        separator(name: "MAIN_PARAM", sectionHeader: "RELEASE / Auftrag Einstellung", separatorStyle: "border-width: 3px", sectionHeaderStyle: "background-color: #90ee90"),
        [$class: 'CascadeChoiceParameter',
            choiceType: 'PT_SINGLE_SELECT',
            description: 'Release Auswahl, TPO SW Unterverzeichnis zum synchronisieren',
            name: 'RELEASE',
            script: [$class: 'GroovyScript', fallbackScript: [classpath: [], sandbox: false, script: ''],
            script: [classpath: [], sandbox: false, script: '''
                def result = []
                new File( "/var/jenkins_home/jenkinsDateneinsatzConfig/generated/RELEASE" ).eachLine { line ->
                    result.add(line)
                }
                return result
        ''']]],
        [$class: 'CascadeChoiceParameter',
            choiceType: 'PT_SINGLE_SELECT',
            description: '',
            name: 'KM_VERSION',
            referencedParameters: 'RELEASE',
            script: [$class: 'GroovyScript', fallbackScript: [classpath: [], sandbox: false, script: ''],
            script: [classpath: [], sandbox: false, script: '''
        def result = []
        // new File("/usr/share/hdm/jenkins/workspace/TPO_SWEinsatz_VersionList/versionList_${RELEASE}.txt" ).eachLine { line ->
        new File("/var/jenkins_home/workspace/TPO_SWEinsatz_VersionList/versionList_${RELEASE}.txt" ).eachLine { line ->
            result.add(line)
        }
        return result.sort().reverse()
        ''']]],
        separator(name: "Auswahl_Aktion", sectionHeader: "Abschnitt Auswahl", separatorStyle: "border-width: 3px", sectionHeaderStyle: "background-color: #90ee90"),
        booleanParam(name: 'SW_S3Sync', defaultValue: true, description: 'Toggle this on if you want sync SW archive from Artifactory into S3'),
        booleanParam(name: 'UPDATE_KM_VERSION', defaultValue: true, description: 'Toggle this on if you want to update version file'),
        booleanParam(name: 'DIRECT_SW_INSTALL', defaultValue: true, description: 'Toggle this on if you want to install update'),
        booleanParam(name: 'DEPLOY_NEW_BASE_IMAGE_AL2023', defaultValue: false, description: 'Toggle this on if you want to start deploying new base image by AWS Stack update and TPO is AL2023'),
        booleanParam(name: 'compare_data', defaultValue: false, description: 'Toggle this on if you want to compare actual SW packets and do smoketest on bibe and tpo servers'),
        separator(name: "Auswahl_PSX_Umgebungen", sectionHeader: "Auswahl PSX Umgebungen", separatorStyle: "border-width: 3px", sectionHeaderStyle: "background-color: #90ee90"),
    ]

stageParamsMap.each { key, value ->
    def uppercaseENV = key.toUpperCase()
    def dyn_parameter = [$class: 'CascadeChoiceParameter',
            choiceType: 'PT_SINGLE_SELECT',
            description: '',
            name: "env_$key",
            referencedParameters: 'RELEASE',
            script: [$class: 'GroovyScript', fallbackScript: [classpath: [], sandbox: false, script: ''],
            script: [classpath: [], sandbox: false, script: """
                def envRel= new File( "/var/jenkins_home/jenkinsDateneinsatzConfig/generated/ENV_${uppercaseENV}_RELEASE" ).text.trim()
                if (envRel.indexOf(RELEASE) != -1) {
                    return ['enable', '-']
                }
                return ['-', 'enable']
        """]]]
    customParamList.add(dyn_parameter)
}

properties([parameters(customParamList), [$class: 'RebuildSettings', autoRebuild: false, rebuildDisabled: false]])
pipeline {
    agent { label jenkinsOps.defaultAgentLabel() }

    stages {
        stage('SW S3SYNC') {
            when {
                expression { params.SW_S3Sync == true }
            }
            steps{
                script {
                    def temp_dir = "${WORKSPACE}/tpo_archives"
                    sh "rm ${temp_dir} -rf && mkdir -p ${temp_dir}"
                    rtServer (
                        id: 'bahnhub',
                        url: 'https://bahnhub.tech.rz.db.de:443/artifactory/',
                        credentialsId: 'artifactory-techuser-psx',
                        bypassProxy: true,
                        timeout: 300
                    )
                    rtDownload (
                        serverId: 'bahnhub',
                        spec: """{
                            "files": [
                                {
                                "pattern": "cvs-generic-stage-dev-local/prod/EXTERN-S-TPO/version_${RELEASE}.*.${KM_VERSION}/vl-nps*",
                                "target": "${temp_dir}/",
                                "flat": true
                                },
                                {
                                "pattern": "cvs-generic-stage-dev-local/prod/EXTERN-S-TPO/version_${RELEASE}.*.${KM_VERSION}/twe*",
                                "target": "${temp_dir}/",
                                "flat": true
                                }
                            ]
                        }"""
                    )
                    def vlFiles = findFiles(glob: "**/vl-nps-*.ami.tar.bz2")
                    echo "DEBUG: $vlFiles"
                    if (vlFiles.length == 0) {
                        error(' Es konnte kein vl Archiv-File gefunden werden. Bitte prüfen Sie das Repository manuell')
                    }
                    def tweFiles = findFiles(glob: "**/twe-*.ami.tar.bz2")
                    echo "DEBUG: $tweFiles"
                    if (tweFiles.length == 0) {
                        error(' Es konnte kein twe Archiv-File gefunden werden. Bitte prüfen Sie das Repository manuell')
                    }
                    sh "aws s3 sync ${temp_dir} s3://556971410989-common-software/TPO/${RELEASE}/${KM_VERSION} --size-only --no-progress"
                }
            }
        }

        stage('UPDATE KM VERSION') {
            steps {
                script {
                    stageParamsMap.each { key, value ->
                        stage("$key", params["env_$key"]  == 'enable' && params.UPDATE_KM_VERSION, {
                            catchError(buildResult: 'UNSTABLE', stageResult: 'FAILURE') {
                                run_with_ssh_agent("./TPO_updateVersion_S3.sh \'SW;${RELEASE};${KM_VERSION};\' \'${key}\'")
                            }
                        })
                    }
                }
            }
        }

        stage('DIRECT SW INSTALL') {
            steps {
                script {
                    def branches = [:]
                    stageParamsMap.each { key, value ->
                        branches["$key"] = { stage("$key", params["env_$key"]  == 'enable' && params.DIRECT_SW_INSTALL, {
                            run_with_ssh_agent("./TPO_installSW.sh \'${key}\'")
                        })}
                    }
                    parallel branches
                }
            }
        }

        stage('DEPLOY LATEST BASE IMAGE AL2023') {
            steps {
                script {
                    def stageSucceeded = false
                    def amiUpdateList = []
                    stageParamsMap.each { key, value ->
                        stage("$key", params["env_$key"]  == 'enable' && params.DEPLOY_NEW_BASE_IMAGE_AL2023, {
                            catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
                                try {
                                    run_with_ssh_agent("./TPO_deploy_LatestBI_withJenkins_al23.sh \'${key}\'")
                                    // addInfoBadge(text: "Latest base AMI deployed")
                                    amiUpdateList.add(key.toString().concat(" -> AMI deployed"));
                                    stageSucceeded = true
                                } catch (Exception exception) {
                                    addWarningBadge(text: key.toString().concat(" -> AMI not deployed"))
                                    // amiUpdateList.add(key.toString() + " -> " + exception.getMessage())
                                }
                            }
                        })
                    }
                    if (stageSucceeded) {
                        addInfoBadge(text: amiUpdateList.toString());
                    }
                }
            }
        }

        stage('WAIT FOR STACK UPDATE COMPLETE') {
            steps {
                script {
                    stageParamsMap.each { key, value ->
                        stage("$key", params["env_$key"]  == 'enable' && (params.DEPLOY_NEW_BASE_IMAGE_AL2023), {
                            sh "aws cloudformation wait stack-update-complete --stack-name tpo-psx${key}-appsrv"
                            sh """
                                if [ `aws cloudformation describe-stack-events --stack-name tpo-psx${key}-appsrv --max-items 1 --output text --query 'StackEvents[*].ResourceStatus' | grep 'UPDATE_COMPLETE'` = 'UPDATE_COMPLETE' ]
                                then
                                    echo "stack upddate succeed"
                                else
                                    echo "ERROR: expected status UPDATE_COMPLETE not recognized"
                                    exit 11
                                fi
                            """
                        })
                    }
                }
            }
        }

        stage('COMPARING ENVs') {
            when {
                expression { params.compare_data}
            }
            steps{
                script {
                    env.DESC = ""
                    stageParamsMap.each { key, value ->
                        if (params["env_$key"] == 'enable') {
                            env.DESC="${env.DESC} $key"
                        }
                    }
                    catchError(buildResult: 'UNSTABLE', stageResult: 'FAILURE') {
                        run_with_ssh_agent("./compare_bibe_tpo.sh P ${DESC}")
                    }
                }
            }
        }
    }

    post {
        always {
            script {
                currentBuild.description = "${RELEASE} ${KM_VERSION}"
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
                    if (params["env_$key"] == 'enable') {
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

def run_with_ssh_agent(shell_code) {
    jenkinsOps.withDeploymentScripts {
        jenkinsOps.withSshAgent {
            sh script: shell_code
        }
    }
}

def stage(name, execute, block) {
    return stage(name, execute ? block : {
        echo 'Stage "' + name + '" skipped due to when conditional.'
        Utils.markStageSkippedForConditional(STAGE_NAME)
    })
}
