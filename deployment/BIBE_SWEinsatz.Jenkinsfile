#!/usr/bin/env groovy
import org.jenkinsci.plugins.pipeline.modeldefinition.Utils

// Used Scripts & Files:
// -----------------------------------------------------------------------
// /var/jenkins_home/jenkinsDateneinsatzConfig/generated/RELEASE
// /share/SOFTWARE/pe/*
// /share/SOFTWARE/hafas/nvs/*
// /var/jenkins_home/jenkinsDateneinsatzConfig/generated/ENV_*_RELEASE
// BIBE_run_update_IM.sh
// BIBE_PE_S3Sync.sh
// BIBE_PE_CheckVersion.sh
// BIBE_PE_UpdateIM.sh
// BIBE_SERVER_S3Sync.sh
// BIBE_SERVER_CheckVersion.sh
// BIBE_SERVER_UpdateIM.sh
// BIBE_createSnapshot.sh
// BIBE_check_PE_SERVER_Version.sh
// BIBE_deploy_LatestAMI_withJenkins.sh
// compare_bibe_tpo.sh


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
        description: 'imageMaster Auswahl, PE Unterverzeichnis zum synchronisieren, !!! WICHTIG: diese Wert ist auch für SERVER Einsatz zwingend',
        name: 'RELEASE', 
        script: [$class: 'GroovyScript', fallbackScript: [classpath: [], sandbox: false, script: ''], 
        script: [classpath: [], sandbox: false, script: '''
            def result = []
            new File( "/var/jenkins_home/jenkinsDateneinsatzConfig/generated/RELEASE" ).eachLine { line ->
                result.add(line)
            }
            return result
    ''']]],
    string(name: 'KM',  defaultValue: 'xxxxx', description: 'KM Auftragnummer'),
    string(name: 'COMMENT',  defaultValue: 'xxx', description: 'additional, optional comment'),
    separator(name: "PE_SEP", sectionHeader: "PE Einsatz Einstellungen", separatorStyle: "border-width: 3px", sectionHeaderStyle: "background-color: #90ee90"),
    [$class: 'CascadeChoiceParameter', 
        choiceType: 'PT_SINGLE_SELECT', 
        description: 'PE Subversion from list (main release version is chosen with choices)',
        name: 'PE_Subversion', 
        referencedParameters: 'RELEASE',
        script: [$class: 'GroovyScript', fallbackScript: [classpath: [], sandbox: false, script: ''], 
        script: [classpath: [], sandbox: false, script: '''
            def year = RELEASE.substring(2,4)
            def month = RELEASE.substring(4,6)
            def proc = "ls /share/SOFTWARE/pe/pe-${year}.${month}/AL23".execute()
            def stdout = new StringBuffer()
            def stderr = new StringBuffer()
            proc.waitForProcessOutput(stdout, stderr)
            def pe_list = stdout.toString().tokenize().grep(~/AL23-pe-${year}.${month}.*/)
            def result = []
            // pe_list.each { pe_zip ->
            //     tmp = pe_zip.take(pe_zip.lastIndexOf('.'))
            //     result << tmp.take(tmp.lastIndexOf('.'))  - "pe-${year}.${month}."
            // }
            // //result = result.sort{ a, b -> a.tokenize('.').last().toInteger() <=> b.tokenize('.').last().toInteger() }.reverse()
            pe_list.each { pe_tarball ->
                def whithoutTarball = pe_tarball.take(pe_tarball.lastIndexOf('.', pe_tarball.lastIndexOf('.') - 1))
                result << whithoutTarball - "AL23-pe-${year}.${month}."
            }
            return result.reverse()
    ''']]],
    booleanParam(name: 'PE', defaultValue: false, description: 'Install PE into imageMaster'),
    separator(name: "SERVER_SEP", sectionHeader: "SERVER Einsatz Einstellungen", separatorStyle: "border-width: 3px", sectionHeaderStyle: "background-color: #90ee90"),
    choice(name: 'current_server_release', choices: ['nvs-release-29', 'nvs-release-30', 'nvs-release-31' ], description: "SERVER Unterverzeichnis zum synchronisieren"),
    [$class: 'CascadeChoiceParameter', 
        choiceType: 'PT_SINGLE_SELECT', 
        description: 'SERVER Subversion (full version, should be corespodent with current server release, ex. 22k-2019-11-18',
        name: 'SERVER_VERSION', 
        referencedParameters: 'current_server_release',
        script: [$class: 'GroovyScript', fallbackScript: [classpath: [], sandbox: false, script: ''], 
        script: [classpath: [], sandbox: false, script: '''
            def proc = "ls /share/SOFTWARE/hafas/nvs/${current_server_release}".execute()
            def stdout = new StringBuffer()
            def stderr = new StringBuffer()
            proc.waitForProcessOutput(stdout, stderr)
            def server_list = stdout.toString().tokenize().grep(~/nvs-.*/).sort().reverse()
            def result = []
            server_list.each { server_tgz ->
                withoutTgz = server_tgz.take(server_tgz.indexOf('.'))
                result << withoutTgz - "nvs-"
            }
            return result
    ''']]],
    booleanParam(name: 'SERVER', defaultValue: false, description: 'Install SERVER into imageMaster'),
    separator(name: "Auswahl_Aktion", sectionHeader: "Abschnitt Auswahl", separatorStyle: "border-width: 3px", sectionHeaderStyle: "background-color: #90ee90"),
    booleanParam(name: 'SW_S3Sync', defaultValue: true, description: 'Toggle this on if you want sync SW archive data from NAS Share into S3'),
    booleanParam(name: 'createSnapshot', defaultValue: true, description: 'Toggle this on if you want to create snapshot (image) for current imageMaster'),
    booleanParam(name: 'DEPLOY_LATEST_SNAPSHOT', defaultValue: true, description: 'Toggle this on if you want deploy latest image into PSX BiBe envinronments'),
    booleanParam(name: 'kernel_update', defaultValue: false, description: 'Toggle this on if you want to check version before deploy latest snapshot'),
    booleanParam(name: 'compare_data', defaultValue: true, description: 'Toggle this on if you want to compare actual SW packets and do smoke test on bibe and tpo psx envinroment'),
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

def releaseHelper = ""
def imageMaster = ""
def commentHelper = ""

properties([parameters(customParamList), [$class: 'RebuildSettings', autoRebuild: false, rebuildDisabled: false]])
pipeline {
    agent { label 'master' }

    stages {

        stage('set imageMaster Parameter') {
            steps {
                script {
                    releaseHelper = params.RELEASE.drop(2).take(4)
                    echo "${releaseHelper}"
                    imageMaster = "nvs-psx-bibe-imageMasterAl23-${releaseHelper}"
                    echo "${imageMaster}"
                }
            }
        }
        
        stage('PREREQs') {
            parallel {
                stage('setting comment') {
                    steps{
                        script {
                            if ( params.PE ) {
                                def versionHelper = params.RELEASE.drop(2).take(2) + "." + params.RELEASE.drop(4).take(2)  
                                commentHelper = "PE AL23 ${versionHelper}.${PE_Subversion} "
                            }
                            if ( params.SERVER ) {
                                commentHelper += "SERVER ${SERVER_VERSION}"
                            }
                            if ( params.COMMENT != "" ) {
                                commentHelper += " - ${params.COMMENT}"
                            }
                            echo "${commentHelper}"
                        }
                    }
                }
                stage('run+update image_master') {
                    when {
                        expression { params.createSnapshot || params.PE || params.SERVER || params.kernel_update }
                    }
                    steps{
                        run_with_ssh_agent("./BIBE_run_update_IM.sh \'${imageMaster}\'")
                    }
                }
            }
        }

        stage('SW S3SYNC PE') {
            when {
                expression { params.SW_S3Sync && params.PE }
            }
            steps{
                run_with_ssh_agent("./BIBE_PE_S3Sync.sh \'${RELEASE}\'")
            }
        }

        stage('CHECK PE VERSION') {
            when {
                expression { params.PE }
            }
            steps{
                catchError(buildResult: 'UNSTABLE', stageResult: 'FAILURE') {
                    run_with_ssh_agent("./BIBE_PE_CheckVersion.sh \'${RELEASE}\' \'${PE_Subversion}\' \'${imageMaster}\'")
                }
            }
        }

        stage('IMAGEMASTER INSTALL PE') {
            when {
                expression { params.PE }
            }
            steps{
                run_with_ssh_agent("./BIBE_PE_UpdateIM.sh \'${RELEASE}\' \'${PE_Subversion}\' \'${imageMaster}\'")
            }
        }

        stage('SW S3SYNC SERVER') {
            when {
                expression { params.SW_S3Sync && params.SERVER }
            }
            steps{
                run_with_ssh_agent("./BIBE_SERVER_S3Sync.sh \'${current_server_release}\'")
            }
        }

       stage('CHECK SERVER VERSION') {
            when {
                expression { params.SERVER }
            }
            steps{
                catchError(buildResult: 'UNSTABLE', stageResult: 'FAILURE') {
                    run_with_ssh_agent("./BIBE_SERVER_CheckVersion.sh \'${imageMaster}\' \'${SERVER_VERSION}\'")
                }
            }
        }

        stage('IMAGEMASTER INSTALL SERVER') {
            when {
                expression { params.SERVER }
            }
            steps{
                run_with_ssh_agent("./BIBE_SERVER_UpdateIM.sh \'${imageMaster}\' \'${SERVER_VERSION}\'")
            }
        }

        stage('CREATE SNAPSHOT') {
            when {
                expression { params.createSnapshot }
            }
            steps{
                run_with_ssh_agent("./BIBE_createSnapshot.sh \'${imageMaster}\' \'${commentHelper}\' \'${KM}\'")
            }
        }
        
        stage('DEPLOY LATEST AMI SNAPSHOT') {
            steps {
                script {
                    stageParamsMap.each { key, value ->
                        def branches = [:]
                        branches[key] = {
                        stage(key, params["env_$key"]  == 'enable' && params.DEPLOY_LATEST_SNAPSHOT, {
                            catchError(buildResult: 'UNSTABLE', stageResult: 'FAILURE') {
                                if (params.kernel_update) {    
                                    run_with_ssh_agent("./BIBE_check_PE_SERVER_Version.sh \'${imageMaster}\'  \'${key}\'")
                                }
                                run_with_ssh_agent("./BIBE_deploy_LatestAMI_withJenkins.sh \'${imageMaster}\' \'${key}\'")
                            }
                        }) }
                        parallel branches
                    }
                }
            }
        }

        stage('WAIT FOR STACK UPDATE COMPLETE') {
            steps {
                script {
                    stageParamsMap.each { key, value ->
                        stage(key, params["env_$key"]  == 'enable' && params.DEPLOY_LATEST_SNAPSHOT, { 
                            sh "aws cloudformation wait stack-update-complete --stack-name nvs-psx${key}-bibe"
                            sh """
                                if [ `aws cloudformation describe-stack-events --stack-name nvs-psx${key}-bibe --max-items 1 --output text --query 'StackEvents[*].ResourceStatus' | grep 'UPDATE_COMPLETE'` = 'UPDATE_COMPLETE' ]
                                then
                                    echo "stack update succeeded" 
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
                expression { params.compare_data }
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
                currentBuild.description = "Release: ${RELEASE}\n KM: ${KM}\n Kommentar: ${commentHelper}"
                def buildUser = "unknown"
                wrap([$class: 'BuildUser']) {
                    try {
                        buildUser = BUILD_USER
                    } catch (e) {
                        echo "User not in scope, probably triggered from another job"
                    }
                }
                addBadge(text: buildUser.toString());
                if (params.PE) { addBadge(text: "R " + RELEASE.drop(2).take(4).toString().concat(" - PE: " + PE_Subversion.toString())) }
                if (params.SERVER) { addBadge(text: "R " + RELEASE.drop(2).take(4).toString().concat(" - SER: " + SERVER_VERSION.toString())) }
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
    dir("deployment") {
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
