#!groovy
pipeline {
    agent { label 'master' }

    triggers {
        cron('H 8 * * 1-5')
    }

    stages {
        stage('Detect latest Base AMI') {
            steps {
                script {

                    def filePath = "scripts/deployment/latest-ami.info"
                    def currentBaseAmi = ""
                    def latestBaseAmi = ""

                    try {
                        if ( fileExists(filePath) ) {
                            currentBaseAmi = readFile(filePath).trim()
                            latestBaseAmi = getLatestAmi(filePath)
                            if ( currentBaseAmi == latestBaseAmi ) {
                                echo "Nothing to do. Current baseAmi: ${currentBaseAmi}"
                            } else if ( currentBaseAmi != latestBaseAmi ) {
                                echo "New latest base image: ${latestBaseAmi}"
                                sendMail("New latest base image: ${latestBaseAmi}")
                            }
                        }
                        else {
                            latestBaseAmi = getLatestAmi(filePath)
                            echo "No history detected, new file generated. Latest base image: ${latestBaseAmi}"
                            sendMail("No history detected, new file generated. Latest base image: ${latestBaseAmi}")
                            currentBuild.result = 'UNSTABLE'
                        }
                    } catch(err) {
                        echo "Caught: ${err}"
                        sendMail("Pipeline failure: ${err}")
                        currentBuild.result = 'FAILURE'
                    }

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
                addInfoBadge(text: buildUser.toString())
            }
        }
    }
}

def getLatestAmi(String outputFilePath) {
    sh """
        aws ec2 describe-images \
        --owners self \
        --region eu-central-1 \
        --filters 'Name=tag:BaseAmiName,Values=al2023-ami-*' \
        --query 'sort_by(Images, &CreationDate)[-1].[ImageId,CreationDate]' \
        --output text >"${outputFilePath}"
    """
    return readFile(outputFilePath).trim()
}

def sendMail(String body) {
    mail(
        to: "psx@deutschebahn.com",
        subject: "Base Image Information (Jenkins Pipeline detect latest base ami)",
        body: body
    )
}
