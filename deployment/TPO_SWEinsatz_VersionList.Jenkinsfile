#!groovy
def REL_ARR = []
pipeline {
    agent { label 'master' }
    parameters {
        string(name: 'RELEASES', defaultValue: '', description: 'additional Releases to create versionList(ex. 20201213,20201001,20200614,20200801)')
    }

    triggers {
        cron('H 6,8,10,12,14,16 * * 1-5')
    }

    stages {
        stage('GET RELEASE LIST') {
            steps{
                script {
                    def config = new ConfigSlurper().parse(new File('/var/jenkins_home/jenkinsDateneinsatzConfig/Configuration.groovy').toURL())
                    config.RELEASE.each { RELEASE -> 
                        REL_ARR.add(RELEASE)
                    }
                    if (RELEASES != '') {
                        RELEASES.split(',').each { RELEASE -> 
                            REL_ARR.add(RELEASE)
                        }
                    }
                    echo "DEBUG: ${REL_ARR}"
                }
            }
        }
        stage('CREATE VERSION LIST') {
            steps{
                script {
                    REL_ARR.each { RELEASE ->
                    def KM_List = ''
                    def aql = """items.find({
                        "repo":{"\$eq":"cvs-generic-stage-dev-local"},
                        "path":{"\$eq":"prod/EXTERN-S-TPO"},
                        "name":{"\$match":"version_$RELEASE*"},
                        "type":"folder"})
                        .include("name","path","repo").sort({"\$desc":["name"]})"""
                    withCredentials([usernamePassword(credentialsId: 'artifactory-techuser-psx', usernameVariable: 'ARTIFACTORY_USER', passwordVariable: 'ARTIFACTORY_PW')]) {
                        String response = sh( script: "curl -u$ARTIFACTORY_USER:$ARTIFACTORY_PW -X POST https://bahnhub.tech.rz.db.de:443/artifactory/api/search/aql -H 'Content-Type: text/plain' -d '$aql'", returnStdout: true)
                        //echo "TRACE: $response"
                        def jsonObj = readJSON text: response
                        jsonObj['results'].each { item ->
                            def km_temp = item['name'].tokenize('.')[-1]
                            KM_List = "${KM_List}${km_temp}\n"
                        }
                    }
                    echo "DEBUG: Versionlist($RELEASE):\n$KM_List"
                    writeFile file: "versionList_${RELEASE}.txt", text: KM_List
                    sh "aws s3 cp versionList_${RELEASE}.txt s3://556971410989-common-software/TPO/${RELEASE}/versionList.txt --no-progress"
                    }
                }
            }
        }
    }
}