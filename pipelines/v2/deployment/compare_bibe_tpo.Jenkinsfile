#!groovy
@Library('jenkins') _
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
        separator(name: "MAIN_PARAM", sectionHeader: "RELEASE Einstellung", separatorStyle: "border-width: 3px", sectionHeaderStyle: "background-color: #90ee90"),
        [$class: 'CascadeChoiceParameter',
            choiceType: 'PT_SINGLE_SELECT',
            description: 'Release Auswahl für default Einstellung aktivierte Umgebungen',
            name: 'RELEASE',
            script: [$class: 'GroovyScript', fallbackScript: [classpath: [], sandbox: false, script: ''],
            script: [classpath: [], sandbox: false, script: '''
                def config = new ConfigSlurper().parse(new File('/var/jenkins_home/jenkinsDateneinsatzConfig/Configuration.groovy').toURL())
                return config.RELEASE
    ''']]],
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

    triggers {
        cron('H 8 * * 1-6')
    }

    stages {
        stage('COMPARING ENVs') {
            steps{
                script {
                    env.DESC = ""
                    stageParamsMap.each { key, value ->
                        if (params["env_$key"] == 'enable') {
                            env.DESC="${env.DESC} $key"
                        }
                    }
                    run_with_ssh_agent("./compare_bibe_tpo.sh A ${DESC}")
                }
            }
        }
    }

    post {
        always {
            script {
                currentBuild.description = "\n\nRELEASE CONFIGURATION:\n\n" + readConfigfile()
                def buildUser = "unknown"
                wrap([$class: 'BuildUser']) {
                    try {
                        buildUser = BUILD_USER
                    } catch (e) {
                        echo "User not in scope, probably triggered from another job"
                    }
                }
                // manager.addShortText("${buildUser}");
                addInfoBadge(text: buildUser.toString());
                // addHtmlBadge(html: buildUser.toString());
                def environmentsList = []
                stageParamsMap.each { key, value ->
                    if (params["env_$key"] == 'enable') {
                        // manager.addShortText("${key}", "black", "white", "1px", "green");
                        environmentsList.add(key.toString());
                    }
                }
                if ( environmentsList.isEmpty() ) {
                    addWarningBadge(text: "No Environments chosen!");
                } else {
                    addInfoBadge(text: environmentsList.toString());
                }
            }
        }
        failure {
            script {
                wrap([$class: 'BuildUser']) {
                if (BUILD_USER == 'Timer Trigger') {
                def mail_address = 'psx@deutschebahn.com'
                def subject= "Jenkins Meldung: BiBe / TPO live check Issue"
                def body = "Jenkins Pipeline meldet Error. Um die Issue zu analysieren, nutzt diese Link fuer PSX Jenkins https://infra-psx-jenkins.dbv3-test.comp.db.de:8443/view/Dateneinsatz/job/compare_tpo_bibe/ "
                emailext (
                    subject: "${subject}",
                    body: "${body}",
                    to: "${mail_address}"
                )
                }
                }
            }
        }
    }
}

def readConfigfile() {
    String response = sh( script: "cat /var/jenkins_home/jenkinsDateneinsatzConfig/Configuration.groovy", returnStdout: true)
    return response

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