#!groovy
import org.jenkinsci.plugins.pipeline.modeldefinition.Utils
Envs_2_terminate = [
    //All: ['h', 'i', 'j', 'k', 'l', 'm', 'q'],
    TT:  [
        k: [ PhysicalResourceId: '', InstanceRefreshId: ''],
        q: [ PhysicalResourceId: '', InstanceRefreshId: ''],
    ]
]
pipeline {
    agent { label 'master' }
    parameters {
        choice(name: 'Umgebungen', choices: ['TT'], description: "")
    }

    triggers {
        cron('0 7 * * 1-5')
    }

    stages {
        stage('REFRESH') {
            steps{
                script {
                    Envs_2_terminate[Umgebungen].each { key, value ->
                        stage(key, {
                            //./terminate_psx_bibe.sh \'${key}\'
                            value.PhysicalResourceId = sh (script: """aws cloudformation describe-stack-resources \
                                    --region eu-central-1 \
                                    --logical-resource-id AutoScalingGroupAppNvsCrossAz \
                                    --query 'StackResources[0].PhysicalResourceId' \
                                    --output text\
                                    --stack-name nvs-psx${key}-bibe""", returnStdout:true)
                            value.InstanceRefreshId  = sh (script: """aws autoscaling start-instance-refresh \
                                    --query 'InstanceRefreshes[0].Status' \
                                    --output text \
                                    --region eu-central-1 \
                                    --preferences MinHealthyPercentage=100,InstanceWarmup=450 \
                                    --auto-scaling-group-name ${value.PhysicalResourceId}""", returnStdout:true)
                        })
                    }
                }
            }
        }


        stage('WAIT REFRESH COMPLETE') {
            steps{
                script {
                    //Envs_2_terminate[Umgebungen].each { key, value ->
                        //stage(key, {
                            // while
                            // def refresh_status = sh (script: """aws autoscaling describe-instance-refreshes \
                            //         --region eu-central-1 \
                            //         --output text \
                            //         --query 'InstanceRefreshes[0].Status' \
                            //         --auto-scaling-group-name nvs-psxi-bibe-AutoScalingGroupAppNvsCrossAz-AVDH5ZECK25V \
                            //         --instance-refresh-ids ${value.InstanceRefreshId}
                            // """, returnStdout:true)
                            // if (refresh_status == "Successful") {
                            //     return
                            // }
                        //})
                    //}
                    sleep(time:10,unit:"MINUTES")
                }
            }
        }

        stage('COMPARING ENVs') {
            steps{
                script {
                    env.envs = ""
                    Envs_2_terminate[Umgebungen].each { key, value ->
                        env.envs="${key} ${env.envs}"
                    }
                    run_with_ssh_agent("./compare_bibe_tpo.sh A $envs")
                }
            }
        }
    }

    post {
        always {
            script {
                currentBuild.description = "${Umgebungen}"
                def buildUser = "unknown"
                wrap([$class: 'BuildUser']) {
                    try {
                        buildUser = BUILD_USER
                    } catch (e) {
                        echo "User not in scope, probably triggered from another job"
                    }
                }
                manager.addShortText("${buildUser}");
                Envs_2_terminate[Umgebungen].each { key, value ->
                    manager.addShortText("${key}", "black", "white", "1px", "green");
                }
            }
        }
        failure {
            script {
                def mail_address = 'psx@deutschebahn.com'
                def subject= "Jenkins Meldung: Bei Versuch die BiBe ("
                Envs_2_terminate[Umgebungen].each { key, value ->
                    subject += "${key}, "
                }
                subject += ") zu terminieren"
                def body = "Jekins Pipeline meldet Error. Um die Issue zu analysieren, nutzt diese Link fuer PSX Jenkins https://infra-psx-jenkins.dbv3-test.comp.db.de:8443/view/Utilities/job/terminate_BiBe_cron/ "
                emailext (
                    subject: "${subject}",
                    body: "${body}",
                    to: "${mail_address}"
                )
            }
        }
    }
}

def run_with_ssh_agent(shell_code) {
    dir("scripts/deployment") {
        sshagent(['7f075ad2-e78f-429d-8713-4a6acd5f7dc2']) {
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