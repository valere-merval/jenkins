#!groovy
import hudson.FilePath
import groovy.io.FileType
import hudson.model.ParametersAction
import hudson.model.FileParameterValue
import hudson.model.Executor

def datenTypMap = [
    EKTR19: [ filename: '', code: '_1901001_', file_suffix: '_FULL.tar.bz2', newFilename: '' ], 
    EKTR29: [ filename: '', code: '_2901001_', file_suffix: '_FULL.tar.bz2', newFilename: '' ],
    k90:    [ filename: '', code: '_k90-'    , file_suffix: '.tar.bz2'     , newFilename: '' ],
    ]

pipeline {
    agent { label 'master' }
    
    options {
        disableConcurrentBuilds()
    }

    environment {
        S3_BUCKET='s3://556971410989-common-daten'
        S3_PATH="${S3_BUCKET}/preisdaten/VL_NPS_EBPB"
    }

    parameters {
        string(name: 'EKTR19', defaultValue: 'latest', description: "version number or latest")
        string(name: 'k90', defaultValue: 'latest', description: "version number (4 digits include leading 0) or latest")
        string(name: 'EKTR29', defaultValue: 'latest', description: "version number or latest")
        string(name: 'release_date', defaultValue: '', description: "needed if version number is used (taken from k90 name ex. 2021.07.19)")
        choice(name: 'Umgebung', choices: ['H', 'J', 'M', 'L', 'I', 'K', 'Q', 'N'], description: "")
        string(name: 'Suffix', defaultValue: '', description: "Suffif for this modification (ex. PROGVV-63_LTBW2)")
        file(description: '1. dm file to replace (can be zip or tar.bz2 format !!!ACHTUNG es dürfen nur die Files im Archiv sein keine Ordner !!!!', name: 'file1')
        file(description: '2. dm file to replace', name: 'file2')
        booleanParam(name: 'ARCHIVE_TAR_ARTIFACTS', defaultValue: false, description: '')
    }

    stages {
        stage('Verify Parameters') {
            steps {
                script {
                    if ( file1.isEmpty() && file2.isEmpty() ) {
                        error('Upload Zip file with more "dm files" or plain "dm file"')
                    }
                    if (params.Suffix.isEmpty()) {
                        error('Suffix is empty string, please define it')
                    }
                    datenTypMap.each {key, value ->
                        if((release_date == '' && params[key] != 'latest' ) || ( release_date != '' && params[key] == 'latest' )) {
                            error('Please fill correct ${key} or release_date')
                        }
                    }
                }
            }
        }

        stage('Unstash uploaded files to workspace') {
            steps {
                script {
                    if (!file1.isEmpty()) {
                        def file_in_workspace = unstashParam "file1"
                    }
                    if (!file2.isEmpty()) {
                        def file_in_workspace = unstashParam "file2"
                    }
                }
            }
        }

        stage('Download Hadamaus packages from S3') {
            steps{
                script {
                    def release_date2 = params.release_date.replaceAll('\\.','')
                    echo "DEBUG: ${release_date2}"
                    datenTypMap.EKTR19.filename="EPA3-${Umgebung}${datenTypMap.EKTR19.code}${release_date2}_V${EKTR19}"
                    datenTypMap.EKTR29.filename="EPA3-${Umgebung}${datenTypMap.EKTR29.code}${release_date2}_V${EKTR29}"
                    datenTypMap.k90.filename="EPA3-${Umgebung}${datenTypMap.k90.code}${k90}.${release_date}"

                    datenTypMap.each { key, value ->
                        if (params[key] == 'latest' && release_date == '') {
                            value.filename = sh (
                                script: "aws s3 ls ${S3_PATH}/EPA3-${Umgebung}${value.code} --recursive | sort | tail -n 1 | awk '{print \$4}'",
                                returnStdout: true
                            ).trim().replaceAll('preisdaten/VL_NPS_EBPB/','').replaceAll('_FULL\\.tar\\.bz2','').replaceAll('\\.tar\\.bz2','')
                        }
                        value.newFilename = "${value.filename}_${Suffix}${value.file_suffix}"
                        echo "DEBUG: ${key} -> ${value.filename} ===> {value.newFilename}"
                        assert(value.filename != '')
                        sh "aws s3 cp ${S3_PATH}/${value.filename}${value.file_suffix} ${WORKSPACE}"
                    }
                }
            }
        }

        stage('Extract Hadamaus packages') {
            steps{
                script {
                    sh "mkdir -p ${WORKSPACE}/dm_new"
                    datenTypMap.each { key, value ->
                        sh "mkdir -p ${WORKSPACE}/${key}"
                        assert(value.filename != '')
                        sh "tar -xvf ${WORKSPACE}/${value.filename}${value.file_suffix} -C ${WORKSPACE}/${key}"
                    }
                }
            }
        }

        stage('Move(unpack) uploaded files to dm_new folder') {
            steps {
                script {
                    unpack_move("$file1")
                    unpack_move("$file2")
                }
            }
        }

        stage('Replace upload files (im dm_new folder) with original') {
            steps {
                script {
                    def dm_newfiles = findFiles glob: '**/dm_new/*'
                    dm_newfiles.each { file ->
                        echo "DEBUG: ${file.name}, ${file.path}, ${file.directory}"
                        makeBackup(datenTypMap, file.name)
                        replaceUploadedHadamausFile(datenTypMap, file.name)
                    }
                }
            }
        }

        stage('create new Hadamaus tar.bz2 packages') {
            steps{
                script {
                    datenTypMap.each { key, value ->
                        sh "tar -cvjSf ${WORKSPACE}/${value.newFilename} -C ${WORKSPACE}/${key} ."
                    }
                }
            }
        }

        stage('Upload new Hadamaus packages to S3') {
            steps{
                script {
                    datenTypMap.each { key, value ->
                        sh "aws s3 cp ${WORKSPACE}/${value.newFilename} ${S3_PATH}/${value.newFilename}"
                    }
                }
            }
        }

        stage('Archive as artifacts (Hadamaus only optional)') {
            steps{
                script {
                    archiveArtifacts artifacts: "dm_new/*", onlyIfSuccessful: true, fingerprint: true
                    if (params.ARCHIVE_TAR_ARTIFACTS) {
                        datenTypMap.each { key, value ->
                            archiveArtifacts artifacts: "${value.newFilename}", onlyIfSuccessful: true, fingerprint: true
                        }
                    }
                }
            }
        }
    }
    
    post {
        always {
            script {
                cleanWs()
                currentBuild.description = "${Umgebung};  ${Suffix};  ${release_date}; "
                def buildUser = "unknown"
                wrap([$class: 'BuildUser']) {
                    try {
                        buildUser = BUILD_USER
                    } catch (e) {
                        echo "User not in scope, probably triggered from another job"
                    }
                }
                addBadge(text: buildUser.toString());
                datenTypMap.each { key, value ->
                    // manager.addShortText("${key}: ${value.newFilename}", "black", "white", "1px", "green");
                    addInfoBadge(text: key.toString().concat(": " + value.newFilename.toString()));
                }
            }
        }
    }
}

def unstashParam(String name, String fname = null) {
    def paramsAction = currentBuild.rawBuild.getAction(ParametersAction.class)

    if (paramsAction == null) {
        error "unstashParam: No file parameter named '${name}'"
    }

    for (param in paramsAction.getParameters()) {
        if (param.getName().equals(name)) {
            if (!(param instanceof FileParameterValue)) {
                error "unstashParam: not a file parameter: ${name}"
            }
            if (env['WORKSPACE'] == null) {
                error "unstashParam: no workspace in current context"
            }

            // **Anpassung hier**
            def workspace = new FilePath(new File(env['WORKSPACE']))
            def filename = fname == null ? param.getOriginalFileName() : fname
            def file = workspace.child(filename)
            file.copyFrom(param.getFile())
            return filename
        }
    }
}

def getComputer(name){

    for(computer in Jenkins.getInstance().getComputers()){ 
        if(computer.getDisplayName() == name){
            return computer.getChannel()
        }
    }

    error "Cannot find computer for file parameter workaround"
}

def unpack_move(String filename) {
    if (!filename.isEmpty()) {
        if ("$filename".reverse().take(4).reverse() == ".zip") {
            //extract zip and move to dm_new folder
            unzip zipFile: "${filename}", dir: "${WORKSPACE}/dm_new"
        } else if ("$filename".reverse().take(8).reverse() == ".tar.bz2" || "$filename".reverse().take(7).reverse() == ".tar.xz") {
            sh "tar -xvf ${WORKSPACE}/${filename} -C ${WORKSPACE}/dm_new"
        } else {
            sh "mv ${WORKSPACE}/${filename} ${WORKSPACE}/dm_new/${filename}"
        }

    }
}

def makeBackup(Map datenTypMap, String filename) {
    datenTypMap.each { key, value ->
        def path = key
        if (key == 'k90') {
            path = 'k90/k90'
        }
        sh "if [ -f ${WORKSPACE}/${path}/${filename}.bak ]; then rm -f ${WORKSPACE}/${path}/${filename}.bak; fi"        
        sh "if [ -f ${WORKSPACE}/${path}/${filename} ]; then mv ${WORKSPACE}/${path}/${filename} ${WORKSPACE}/${path}/${filename}.bak; fi"
    }
}

def replaceUploadedHadamausFile(Map datenTypMap, String filename) {
    datenTypMap.each { key, value ->
        def path = key
        if (key == 'k90') {
            path = 'k90/k90'
        }        
        sh "if [ -f ${WORKSPACE}/${path}/${filename}.bak ]; then cp ${WORKSPACE}/dm_new/${filename} ${WORKSPACE}/${path}/${filename}; fi"
    }    
}
