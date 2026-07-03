#!groovy
archive_name = ''
pipeline {
    agent { label 'master' }

    stages {
        stage('create archive from git') {
            steps{
                script {
                    def today = new Date()
                    archive_name = "nvsbibe-app-" + today.format("yy.MM") + ".PSX.tgz"
                    sh "rm -rf nvsbibe-app-*.PSX.tgz"
                    echo "${archive_name}"
                    sh "cd ${WORKSPACE}/ansible-playbook/ && tar -zcvf ../${archive_name} *"
                }
            }
        }

        stage('archive artifact') {
            steps{
                script {
                    archiveArtifacts artifacts: "${archive_name}", onlyIfSuccessful: true, fingerprint: true
                }
            }
        }
    }
    post {
        always {
            script {
                def buildUser = "unknown"
                wrap([$class: 'BuildUser']) {
                    try {
                        buildUser = BUILD_USER
                    } catch (e) {
                        echo "User not in scope, probably triggered from another job"
                    }
                }
                addInfoBadge(text: buildUser.toString());
            }
        }
    }
}