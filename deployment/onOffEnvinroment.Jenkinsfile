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
    booleanParam(name: "dryRun", defaultValue: false, description: "Just to load job from git" ),
    string(name: 'bibeAmi', defaultValue: '', description: 'New Ami to use. Use an empty string for current used ami'),
    string(name: 'tpoAmi', defaultValue: '', description: 'New Ami to use. Use an empty string for current used ami'),
    separator(name: "Umgebung_Auswahl", sectionHeader: "Umgebung für Action", separatorStyle: "border-width: 3px", sectionHeaderStyle: "background-color: #90ee90"),
]

stageParamsMap.each { key, value ->
    customParamList.add(choice(name: "env_${key}", choices: ['-', 'on', 'off'], description: "Toggle this on if you want to control ${key} environemnt"))
}


properties([parameters(customParamList), [$class: 'RebuildSettings', autoRebuild: false, rebuildDisabled: false]])
pipeline {
    agent { label 'master' }
    environment {
        PARENT_DIR = "${env.WORKSPACE}/update-stack/"
    }

    stages {

        stage('LOAD STACK PARAMETERS') {
            when {
                expression { !params.dryRun }
            }
            steps {
                script {
                    currentBuild.description = "STACK PARAMETER:\n\n"
                    def branches = [:]
                    stageParamsMap.keySet().each { key ->
                        def currentKey = key
                        def currentAction = params["env_$key"]
                        branches[key] = {
                            def subBranches = [:]
                            subBranches["BIBE ${currentKey}"] = { stage("BIBE ${currentKey}", currentAction != '-', {
                                def bibeStackParameterMap = getStackParameters("nvs-psx${currentKey}-bibe")
                                bibeStackParameterMap.each { parameter, value ->
                                    setValueInConfigFile("${env.PARENT_DIR}nvs-psx${currentKey}-bibe.cfg", parameter, value, "Parameters")
                                    currentBuild.description += "BIBE ${currentKey} : ${parameter} = ${value}\n"
                                }
                            })}
                            subBranches["TPO ${currentKey}"] = { stage("TPO ${currentKey}", currentAction != '-', {
                                def tpoStackParameterMap = getStackParameters("tpo-psx${currentKey}-appsrv")
                                tpoStackParameterMap.each { parameter, value -> 
                                    setValueInConfigFile("${env.PARENT_DIR}tpo-psx${currentKey}-appsrv.cfg", parameter, value, "Parameters")
                                    currentBuild.description += "TPO ${currentKey}: ${parameter} = ${value}\n"
                                }
                            })}
                            parallel subBranches
                        }
                    }
                    parallel branches
                }
            }
        }

        stage('PREPARE CONFIGURATION FILES') {
            when {
                expression { !params.dryRun }
            }
            steps {
                script {
                    def configPath = "/var/jenkins_home/jenkinsDateneinsatzConfig/Configuration.groovy"
                    def valuesToAddMap = [:]
                    def valuesToRemoveMap = [:]

                    def branches = [:]
                    stageParamsMap.each { key, value ->
                        def action = params["env_$key"]
                        branches[key] = { stage(key, action != '-', {
                            if (action == 'on') {
                                value.action = 1
                                valuesToRemoveMap[key] = "done"
                            } else if (action == 'off'){
                                value.action = 0
                                valuesToAddMap[key] = "done"
                            } else {
                                error("undefined chocie: ${action}")
                            }
                            setValueInConfigFile("${env.PARENT_DIR}nvs-psx${key}-bibe.cfg", "NvsBibeAutoScalingDesiredCapacity", "${value['action']}", "Parameters")
                            setValueInConfigFile("${env.PARENT_DIR}nvs-psx${key}-bibe.cfg", "NvsBibeAutoScalingMaxSize", "${value['action']}", "Parameters")
                            setValueInConfigFile("${env.PARENT_DIR}nvs-psx${key}-bibe.cfg", "NvsBibeAutoScalingMinSize", "${value['action']}", "Parameters")
                            setValueInConfigFile("${env.PARENT_DIR}tpo-psx${key}-appsrv.cfg", "AsgSize", "${value['action']}", "Parameters")
                        })}
                    }
                    parallel branches

                    def valuesToAdd = valuesToAddMap.keySet().toList()
                    def valuesToRemove = valuesToRemoveMap.keySet().toList()
                    modifyPseudoListValuesInConfigfile(configPath, "envs_deactivated" , valuesToRemove, valuesToAdd)
                    generateFilesFromConfig(configPath)
                }
            }
        }

        stage('SET AMIs TO USE') {
            when {
                expression { !params.dryRun }
            }
            steps {
                script {
                    def branches = [:]
                    stageParamsMap.each { key, value ->
                        def currentKey = key
                        def currentValue = value
                        branches[key] = {
                            def subBranches = [:]
                            subBranches["BIBE ${currentKey}"] = { stage("BIBE ${currentKey}", currentValue.action != '-', {
                                if (params.bibeAmi != '') {
                                    setValueInConfigFile("${env.PARENT_DIR}nvs-psx${currentKey}-bibe.cfg", "NvsBibeGoldenImageAmi", params.bibeAmi, "Parameters")
                                    echo "New ${currentKey}-BIBE AMI: ${params.bibeAmi}"
                                } else {
                                    def bibeStackParameterMap = getStackParameters("nvs-psx${currentKey}-bibe")
                                    setValueInConfigFile("${env.PARENT_DIR}nvs-psx${currentKey}-bibe.cfg", "NvsBibeGoldenImageAmi", "${bibeStackParameterMap['NvsBibeGoldenImageAmi']}", "Parameters")
                                    echo "Current ${currentKey}-BIBE AMI: ${bibeStackParameterMap['NvsBibeGoldenImageAmi']}"
                                }
                            })}
                            subBranches["TPO ${currentKey}"] = { stage("TPO ${currentKey}", currentValue.action != '-', {
                                if (params.tpoAmi != '') {
                                    setValueInConfigFile("${env.PARENT_DIR}tpo-psx${currentKey}-appsrv.cfg", "AmiId", params.tpoAmi, "Parameters")
                                    echo "New ${currentKey}-TPO AMI: ${params.tpoAmi}"
                                } else {
                                    def tpoStackParameterMap = getStackParameters("tpo-psx${currentKey}-appsrv")
                                    setValueInConfigFile("${env.PARENT_DIR}tpo-psx${currentKey}-appsrv.cfg", "AmiId", "${tpoStackParameterMap['AmiId']}", "Parameters")
                                    echo "Current ${currentKey}-TPO AMI: ${tpoStackParameterMap['AmiId']}"
                                }
                            })}
                            parallel subBranches
                        }
                    }
                    parallel branches
                }
            }
        }

        stage('ENABLE/DISABLE ENVIROMENT') {
            when {
                expression { !params.dryRun }
            }
            steps {
                script {
                    dir("update-stack") {
                        def branches = [:]
                        stageParamsMap.each { key, value ->
                            def currentKey = key
                            def currentValue = value
                            branches[key] = {
                                def subBranches = [:]
                                subBranches["BIBE ${currentKey}"] = { stage("BIBE ${currentKey}", currentValue.action != '-', {
                                    catchError(buildResult: 'UNSTABLE', stageResult: 'FAILURE') {
                                        def returnStatus = sh (
                                            script: "./update-stack_new.py nvs-psx${currentKey}-bibe.cfg",
                                            returnStatus: true
                                        )
                                        if (returnStatus == 0) {
                                            sh "aws cloudformation wait stack-update-complete --stack-name nvs-psx${currentKey}-bibe"
                                            echo "Stack tpo-psx${currentKey}-appsrv updated successfully"
                                        } else if (returnStatus == 3) {
                                            echo "No update needed for nvs-psx${currentKey}-bibe"
                                            addInfoBadge(text: "No cfn changes for ${currentKey}-bibe")
                                        } else {
                                            error("CloudFormation update failed for nvs-psx${currentKey}-bibe: ${returnStatus}")
                                        }
                                    }
                                })}
                                subBranches["TPO ${currentKey}"] = { stage("TPO ${currentKey}", currentValue.action != '-', {
                                    catchError(buildResult: 'UNSTABLE', stageResult: 'FAILURE') {
                                        def returnStatus = sh (
                                            script: "./update-stack_new.py tpo-psx${currentKey}-appsrv.cfg",
                                            returnStatus: true
                                        )
                                        if (returnStatus == 0) {
                                            sh "aws cloudformation wait stack-update-complete --stack-name tpo-psx${currentKey}-appsrv"
                                            echo "Stack tpo-psx${currentKey}-appsrv updated successfully"
                                        } else if (returnStatus == 3) {
                                            echo "No update needed for tpo-psx${currentKey}-appsrv"
                                            addInfoBadge(text: "No cfn changes for ${currentKey}-tpo")
                                        } else {
                                            error("CloudFormation update failed for tpo-psx${currentKey}-appsrv: ${returnStatus}")
                                        }
                                    }                                    
                                })}
                                parallel subBranches
                            }
                        }
                        parallel branches
                    }
                }
            }
        }

    }
    
    post {
        always {
            script {
                currentBuild.description += "\n\n======================================================\n\nRELEASE CONFIGURATION:\n\n" + catConfigfile()
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


def stage(name, execute, block) {
    return stage(name, execute ? block : {
        echo 'Stage "' + name + '" skipped due to when conditional.'
        Utils.markStageSkippedForConditional(STAGE_NAME)
    })
}

def catConfigfile() {
    String response = sh( script: "cat /var/jenkins_home/jenkinsDateneinsatzConfig/Configuration.groovy", returnStdout: true)
    return response
}

// def parseConfigFile(String configPath) {

//     def configFile = new File(configPath)
//     if (!configFile.exists()) error "File ${configPath} not found!"

//     def config = [:]
//     def currentSection = null

//     configFile.readLines().each { line ->    
//         line = line.trim()
//         // for blank lines and comments
//         if (!line || line.startsWith("//") || line.startsWith("#")) { return line }
//         // for sections
//         if (line.startsWith("[") && line.endsWith("]")) {
//             currentSection = line[1..-2].trim()
//             if (!config.containsKey(currentSection)) {
//                 config[currentSection] = [:]
//             }
//             return line
//         }
//         // for key-value pairs
//         if (line.contains("=") || line.contains(":")) {
//             def (key, value) = line.split(/[:=]/, 2).collect { it.trim() }
//             // def (key, value) = line.split(/[:=]/, 2)*.trim()
//             if (currentSection) {
//                 config[currentSection][key] = value
//             } else {
//                 config[key] = value
//             }
//         }
//     }

//     return config

// }

def setValueInConfigFile(String configPath, String key, String newValue, String section = null) {

    def configFile = new File(configPath)
    if (!configFile.exists()) error "File ${configPath} not found!"

    def lines = configFile.readLines()
    def inSection = (section == null)

    def newLines = lines.collect { line ->
        line = line.trim()
        // for blank lines and comments
        if (!line || line.startsWith("//") || line.startsWith("#")) { return line }
        // for sections
        if (line.startsWith("[") && line.endsWith("]")) {
            inSection = (line[1..-2].trim() == section)
            return line
        }
        // for key-value pairs
        if (inSection) {
            def separatorIndex = line.indexOf(":")
            if (separatorIndex < 0) { separatorIndex = line.indexOf("=") }
            if ((separatorIndex > 0) && (separatorIndex < line.length()-1)) {
                def keyPart = line[0..(separatorIndex-1)].trim()
                def separator = line[separatorIndex]
                def valuePart = line[(separatorIndex+1)..-1].trim()
                if (keyPart == key) {
                    if ((valuePart.startsWith("'") && valuePart.endsWith("'")) || (valuePart.startsWith('"') && valuePart.endsWith('"'))) {
                        return "${key}${separator}${valuePart[0]}${newValue}${valuePart[-1]}"
                    } else {
                        return "${key}${separator} ${newValue}"
                    }
                }
            }
        }
        return line
    }

    configFile.setText(newLines.join("\n") + "\n")

}

def setKeyValuePairInConfigFile(String configPath, String key, String value, String section = null) {

}

def modifyPseudoListValuesInConfigfile(String configPath, String key, List valuesToRemove = [], List valuesToAdd = []) {
    
    def configFile = new File(configPath)
    if (!configFile.exists()) error "File ${configPath} not found!"

    def lines = configFile.readLines()

    def newLines = lines.collect { line ->
        line = line.trim()
        if (line.startsWith(key)) {
            def (k, valuePart) = line.split("=", 2).collect { it.trim() }
            def values = valuePart.replaceAll(/^"|"$/, '')
                                .split("\\|")
                                .collect { it.trim() }
                                .findAll { !valuesToRemove.contains(it) }

            values.addAll(valuesToAdd)
            values = values.unique()
            return "${k}=\"${values.join('|')}\""
        } else {
            return line
        }
    }

    configFile.setText(newLines.join("\n") + "\n")

}

def modifyListValuesInConfigfile(String configPath, String key, List valuesToRemove = [], List valuesToAdd = []) {

    def configFile = new File(configPath)
    if (!configFile.exists()) error "File ${configPath} not found!"

    def lines = configFile.readLines()

    def newLines = lines.collect { line ->

        if (line.trim().startsWith("${key}=")) {

            def (k, valuePart) = line.split("=", 2).collect { it.trim() }

            def values = valuePart
                    .replaceAll(/\[|\]/, '')
                    .split(",")
                    .collect { it.trim().replaceAll('"', '') }
                    .findAll { it }

            values = values.findAll { !valuesToRemove.contains(it) }

            values.addAll(valuesToAdd)
            values = values.unique()

            return "${k}=[${values.collect { "\"${it}\"" }.join(', ')}]"
        }

        return line
    }

    configFile.setText(newLines.join("\n") + "\n")
}

def generateFilesFromConfig(String configPath) {

    def config = new ConfigSlurper().parse(new File(configPath).toURI().toURL())
    def generatedDir = new File(new File(configPath).parent, 'generated')
    generatedDir.mkdir()

    config.each { key, value ->
        def content = (value instanceof List) ? value.join('\n') + '\n' : value.toString()
        new File(generatedDir, key).setText(content)
        echo "DEBUG: ${key} --> ${value}${value instanceof List ? ' (List)' : ''}"
    }

}

def getStackParameters(String stackName) {
    
    // cmd: aws cloudformation describe-stacks --stack-name nvs-psxi-bibe --query "Stacks[0].Parameters[]" --output json | jq 'map({(.ParameterKey): .ParameterValue}) | add'

    def json = sh(
        script: """
          aws cloudformation describe-stacks \
            --stack-name ${stackName} \
            --query "Stacks[0].Parameters[]" \
            --output json
        """,
        returnStdout: true
    ).trim()

    def params = readJSON text: json
    return params.collectEntries { p ->
        [(p.ParameterKey): p.ParameterValue]
    }

}
