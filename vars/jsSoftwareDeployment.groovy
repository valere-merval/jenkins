/**
 * Shared helpers for BIBE/TPO software deployment pipelines.
 *
 * Jenkinsfiles should describe orchestration only; parameter construction,
 * repeated environment loops and operational shell details live here.
 */

def bibeParameters(Map stageParamsMap) {
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

    addEnvironmentParameters(customParamList, stageParamsMap)
    return customParamList
}

def tpoParameters(Map stageParamsMap) {
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

    addEnvironmentParameters(customParamList, stageParamsMap)
    return customParamList
}

def addEnvironmentParameters(List customParamList, Map stageParamsMap) {
    stageParamsMap.each { key, value ->
        customParamList.add(jenkinsOps.environmentChoiceParameter(key))
    }
}

def bibeImageMaster(String release) {
    return "nvs-psx-bibe-imageMasterAl23-${release.drop(2).take(4)}"
}

def bibeComment(Map values) {
    def comment = ''
    if (values.PE) {
        def versionHelper = values.RELEASE.drop(2).take(2) + "." + values.RELEASE.drop(4).take(2)
        comment = "PE AL23 ${versionHelper}.${values.PE_Subversion} "
    }
    if (values.SERVER) {
        comment += "SERVER ${values.SERVER_VERSION}"
    }
    if (values.COMMENT != '') {
        comment += " - ${values.COMMENT}"
    }
    return comment
}

def runBibeImageMaster(String imageMaster) {
    jenkinsOps.runDeploymentShell("./BIBE_run_update_IM.sh '${imageMaster}'")
}

def syncBibePe(String release) {
    jenkinsOps.runDeploymentShell("./BIBE_PE_S3Sync.sh '${release}'")
}

def checkBibePeVersion(String release, String peSubversion, String imageMaster) {
    catchError(buildResult: 'UNSTABLE', stageResult: 'FAILURE') {
        jenkinsOps.runDeploymentShell("./BIBE_PE_CheckVersion.sh '${release}' '${peSubversion}' '${imageMaster}'")
    }
}

def installBibePe(String release, String peSubversion, String imageMaster) {
    jenkinsOps.runDeploymentShell("./BIBE_PE_UpdateIM.sh '${release}' '${peSubversion}' '${imageMaster}'")
}

def syncBibeServer(String currentServerRelease) {
    jenkinsOps.runDeploymentShell("./BIBE_SERVER_S3Sync.sh '${currentServerRelease}'")
}

def checkBibeServerVersion(String imageMaster, String serverVersion) {
    catchError(buildResult: 'UNSTABLE', stageResult: 'FAILURE') {
        jenkinsOps.runDeploymentShell("./BIBE_SERVER_CheckVersion.sh '${imageMaster}' '${serverVersion}'")
    }
}

def installBibeServer(String imageMaster, String serverVersion) {
    jenkinsOps.runDeploymentShell("./BIBE_SERVER_UpdateIM.sh '${imageMaster}' '${serverVersion}'")
}

def createBibeSnapshot(String imageMaster, String comment, String km) {
    jenkinsOps.runDeploymentShell("./BIBE_createSnapshot.sh '${imageMaster}' '${comment}' '${km}'")
}

def deployBibeLatestSnapshot(Map stageParamsMap, Map values, String imageMaster) {
    stageParamsMap.each { key, value ->
        def branches = [:]
        branches[key] = {
            jenkinsOps.conditionalStage(key, values["env_$key"] == 'enable' && values.DEPLOY_LATEST_SNAPSHOT, {
                catchError(buildResult: 'UNSTABLE', stageResult: 'FAILURE') {
                    if (values.kernel_update) {
                        jenkinsOps.runDeploymentShell("./BIBE_check_PE_SERVER_Version.sh '${imageMaster}'  '${key}'")
                    }
                    jenkinsOps.runDeploymentShell("./BIBE_deploy_LatestAMI_withJenkins.sh '${imageMaster}' '${key}'")
                }
            })
        }
        parallel branches
    }
}

def waitForBibeStackUpdates(Map stageParamsMap, Map values) {
    waitForStackUpdates(stageParamsMap, values, 'DEPLOY_LATEST_SNAPSHOT') { key -> "nvs-psx${key}-bibe" }
}

def syncTpoSoftware(Map values, String workspace) {
    def tempDir = "${workspace}/tpo_archives"
    sh "rm ${tempDir} -rf && mkdir -p ${tempDir}"
    rtServer(
        id: 'bahnhub',
        url: 'https://bahnhub.tech.rz.db.de:443/artifactory/',
        credentialsId: 'artifactory-techuser-psx',
        bypassProxy: true,
        timeout: 300
    )
    rtDownload(
        serverId: 'bahnhub',
        spec: """{
            "files": [
                {
                "pattern": "cvs-generic-stage-dev-local/prod/EXTERN-S-TPO/version_${values.RELEASE}.*.${values.KM_VERSION}/vl-nps*",
                "target": "${tempDir}/",
                "flat": true
                },
                {
                "pattern": "cvs-generic-stage-dev-local/prod/EXTERN-S-TPO/version_${values.RELEASE}.*.${values.KM_VERSION}/twe*",
                "target": "${tempDir}/",
                "flat": true
                }
            ]
        }"""
    )
    assertFilesFound('**/vl-nps-*.ami.tar.bz2', ' Es konnte kein vl Archiv-File gefunden werden. Bitte prüfen Sie das Repository manuell')
    assertFilesFound('**/twe-*.ami.tar.bz2', ' Es konnte kein twe Archiv-File gefunden werden. Bitte prüfen Sie das Repository manuell')
    sh "aws s3 sync ${tempDir} s3://556971410989-common-software/TPO/${values.RELEASE}/${values.KM_VERSION} --size-only --no-progress"
}

def assertFilesFound(String glob, String message) {
    def files = findFiles(glob: glob)
    echo "DEBUG: $files"
    if (files.length == 0) {
        error(message)
    }
}

def updateTpoKmVersion(Map stageParamsMap, Map values) {
    stageParamsMap.each { key, value ->
        jenkinsOps.conditionalStage("$key", values["env_$key"] == 'enable' && values.UPDATE_KM_VERSION, {
            catchError(buildResult: 'UNSTABLE', stageResult: 'FAILURE') {
                jenkinsOps.runDeploymentShell("./TPO_updateVersion_S3.sh 'SW;${values.RELEASE};${values.KM_VERSION};' '${key}'")
            }
        })
    }
}

def installTpoSoftware(Map stageParamsMap, Map values) {
    def branches = [:]
    stageParamsMap.each { key, value ->
        branches["$key"] = {
            jenkinsOps.conditionalStage("$key", values["env_$key"] == 'enable' && values.DIRECT_SW_INSTALL, {
                jenkinsOps.runDeploymentShell("./TPO_installSW.sh '${key}'")
            })
        }
    }
    parallel branches
}

def deployTpoBaseImage(Map stageParamsMap, Map values) {
    def stageSucceeded = false
    def amiUpdateList = []
    stageParamsMap.each { key, value ->
        jenkinsOps.conditionalStage("$key", values["env_$key"] == 'enable' && values.DEPLOY_NEW_BASE_IMAGE_AL2023, {
            catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
                try {
                    jenkinsOps.runDeploymentShell("./TPO_deploy_LatestBI_withJenkins_al23.sh '${key}'")
                    amiUpdateList.add(key.toString().concat(' -> AMI deployed'))
                    stageSucceeded = true
                } catch (Exception exception) {
                    addWarningBadge(text: key.toString().concat(' -> AMI not deployed'))
                }
            }
        })
    }
    if (stageSucceeded) {
        addInfoBadge(text: amiUpdateList.toString())
    }
}

def waitForTpoStackUpdates(Map stageParamsMap, Map values) {
    waitForStackUpdates(stageParamsMap, values, 'DEPLOY_NEW_BASE_IMAGE_AL2023') { key -> "tpo-psx${key}-appsrv" }
}

def waitForStackUpdates(Map stageParamsMap, Map values, String triggerParam, Closure stackNameForEnv) {
    stageParamsMap.each { key, value ->
        jenkinsOps.conditionalStage("$key", values["env_$key"] == 'enable' && values[triggerParam], {
            def stackName = stackNameForEnv(key)
            sh "aws cloudformation wait stack-update-complete --stack-name ${stackName}"
            sh """
                if [ `aws cloudformation describe-stack-events --stack-name ${stackName} --max-items 1 --output text --query 'StackEvents[*].ResourceStatus' | grep 'UPDATE_COMPLETE'` = 'UPDATE_COMPLETE' ]
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

def compareBibeTpoSoftware(Map stageParamsMap, Map values) {
    def desc = selectedEnvironmentDescription(stageParamsMap, values)
    catchError(buildResult: 'UNSTABLE', stageResult: 'FAILURE') {
        jenkinsOps.runDeploymentShell("./compare_bibe_tpo.sh P ${desc}")
    }
    return desc
}

def selectedEnvironmentDescription(Map stageParamsMap, Map values) {
    def desc = ''
    stageParamsMap.each { key, value ->
        if (values["env_$key"] == 'enable') {
            desc = "${desc} $key"
        }
    }
    return desc
}

def addBuildUserBadge() {
    def buildUser = 'unknown'
    wrap([$class: 'BuildUser']) {
        try {
            buildUser = BUILD_USER
        } catch (e) {
            echo 'User not in scope, probably triggered from another job'
        }
    }
    addBadge(text: buildUser.toString())
}

def addEnvironmentBadges(Map stageParamsMap, Map values) {
    def environmentsList = []
    stageParamsMap.each { key, value ->
        if (values["env_$key"] == 'enable') {
            environmentsList.add(key.toString())
        }
    }
    if (environmentsList.isEmpty()) {
        addWarningBadge(text: 'No Environments chosen!')
    } else {
        addBadge(text: environmentsList.toString())
    }
}

def addBibePostBadges(Map stageParamsMap, Map values) {
    addBuildUserBadge()
    if (values.PE) {
        addBadge(text: 'R ' + values.RELEASE.drop(2).take(4).toString().concat(' - PE: ' + values.PE_Subversion.toString()))
    }
    if (values.SERVER) {
        addBadge(text: 'R ' + values.RELEASE.drop(2).take(4).toString().concat(' - SER: ' + values.SERVER_VERSION.toString()))
    }
    addEnvironmentBadges(stageParamsMap, values)
}

def addTpoPostBadges(Map stageParamsMap, Map values) {
    addBuildUserBadge()
    addEnvironmentBadges(stageParamsMap, values)
}
