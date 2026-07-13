/** Shared orchestration for the on/off environment control pipeline. */

def stageParams() {
    return [
        h: [action: '-'],
        i: [action: '-'],
        j: [action: '-'],
        k: [action: '-'],
        l: [action: '-'],
        m: [action: '-'],
        q: [action: '-']
    ]
}

def parameters(Map stageParamsMap) {
    def customParamList = [
        booleanParam(name: 'dryRun', defaultValue: false, description: 'Just to load job from git'),
        string(name: 'bibeAmi', defaultValue: '', description: 'New Ami to use. Use an empty string for current used ami'),
        string(name: 'tpoAmi', defaultValue: '', description: 'New Ami to use. Use an empty string for current used ami'),
        separator(name: 'Umgebung_Auswahl', sectionHeader: 'Umgebung für Action', separatorStyle: 'border-width: 3px', sectionHeaderStyle: 'background-color: #90ee90'),
    ]
    stageParamsMap.each { key, value ->
        customParamList.add(choice(name: "env_${key}", choices: ['-', 'on', 'off'], description: "Toggle this on if you want to control ${key} environemnt"))
    }
    return customParamList
}

def loadStackParameters(Map stageParamsMap, Map values, String parentDir) {
    currentBuild.description = 'STACK PARAMETER:\n\n'
    def branches = [:]
    stageParamsMap.keySet().each { key ->
        def currentKey = key
        def currentAction = values["env_$key"]
        branches[key] = {
            def subBranches = [:]
            subBranches["BIBE ${currentKey}"] = { jenkinsOps.conditionalStage("BIBE ${currentKey}", currentAction != '-', {
                persistStackParameters("nvs-psx${currentKey}-bibe", "${parentDir}nvs-psx${currentKey}-bibe.cfg", "BIBE ${currentKey}")
            })}
            subBranches["TPO ${currentKey}"] = { jenkinsOps.conditionalStage("TPO ${currentKey}", currentAction != '-', {
                persistStackParameters("tpo-psx${currentKey}-appsrv", "${parentDir}tpo-psx${currentKey}-appsrv.cfg", "TPO ${currentKey}")
            })}
            parallel subBranches
        }
    }
    parallel branches
}

def persistStackParameters(String stackName, String configPath, String descriptionPrefix) {
    jsConfigFile.stackParameters(stackName).each { parameter, value ->
        jsConfigFile.setValueInConfigFile(configPath, parameter, value, 'Parameters')
        currentBuild.description += "${descriptionPrefix} : ${parameter} = ${value}\n"
    }
}

def prepareConfigurationFiles(Map stageParamsMap, Map values, String parentDir, String configPath) {
    def valuesToAddMap = [:]
    def valuesToRemoveMap = [:]
    def branches = [:]

    stageParamsMap.each { key, value ->
        def action = values["env_$key"]
        branches[key] = { jenkinsOps.conditionalStage(key, action != '-', {
            if (action == 'on') {
                value.action = 1
                valuesToRemoveMap[key] = 'done'
            } else if (action == 'off') {
                value.action = 0
                valuesToAddMap[key] = 'done'
            } else {
                error("undefined chocie: ${action}")
            }
            setEnvironmentCapacity(parentDir, key, value.action)
        })}
    }
    parallel branches

    jsConfigFile.modifyPseudoListValuesInConfigfile(configPath, 'envs_deactivated', valuesToRemoveMap.keySet().toList(), valuesToAddMap.keySet().toList())
    jsConfigFile.generateFilesFromConfig(configPath)
}

def setEnvironmentCapacity(String parentDir, String key, Object action) {
    jsConfigFile.setValueInConfigFile("${parentDir}nvs-psx${key}-bibe.cfg", 'NvsBibeAutoScalingDesiredCapacity', "${action}", 'Parameters')
    jsConfigFile.setValueInConfigFile("${parentDir}nvs-psx${key}-bibe.cfg", 'NvsBibeAutoScalingMaxSize', "${action}", 'Parameters')
    jsConfigFile.setValueInConfigFile("${parentDir}nvs-psx${key}-bibe.cfg", 'NvsBibeAutoScalingMinSize', "${action}", 'Parameters')
    jsConfigFile.setValueInConfigFile("${parentDir}tpo-psx${key}-appsrv.cfg", 'AsgSize', "${action}", 'Parameters')
}

def setAmisToUse(Map stageParamsMap, Map values, String parentDir) {
    def branches = [:]
    stageParamsMap.each { key, value ->
        def currentKey = key
        def currentValue = value
        branches[key] = {
            def subBranches = [:]
            subBranches["BIBE ${currentKey}"] = { jenkinsOps.conditionalStage("BIBE ${currentKey}", currentValue.action != '-', {
                setBibeAmi(parentDir, currentKey, values.bibeAmi)
            })}
            subBranches["TPO ${currentKey}"] = { jenkinsOps.conditionalStage("TPO ${currentKey}", currentValue.action != '-', {
                setTpoAmi(parentDir, currentKey, values.tpoAmi)
            })}
            parallel subBranches
        }
    }
    parallel branches
}

def setBibeAmi(String parentDir, String key, String requestedAmi) {
    if (requestedAmi != '') {
        jsConfigFile.setValueInConfigFile("${parentDir}nvs-psx${key}-bibe.cfg", 'NvsBibeGoldenImageAmi', requestedAmi, 'Parameters')
        echo "New ${key}-BIBE AMI: ${requestedAmi}"
    } else {
        def stackParameterMap = jsConfigFile.stackParameters("nvs-psx${key}-bibe")
        jsConfigFile.setValueInConfigFile("${parentDir}nvs-psx${key}-bibe.cfg", 'NvsBibeGoldenImageAmi', "${stackParameterMap['NvsBibeGoldenImageAmi']}", 'Parameters')
        echo "Current ${key}-BIBE AMI: ${stackParameterMap['NvsBibeGoldenImageAmi']}"
    }
}

def setTpoAmi(String parentDir, String key, String requestedAmi) {
    if (requestedAmi != '') {
        jsConfigFile.setValueInConfigFile("${parentDir}tpo-psx${key}-appsrv.cfg", 'AmiId', requestedAmi, 'Parameters')
        echo "New ${key}-TPO AMI: ${requestedAmi}"
    } else {
        def stackParameterMap = jsConfigFile.stackParameters("tpo-psx${key}-appsrv")
        jsConfigFile.setValueInConfigFile("${parentDir}tpo-psx${key}-appsrv.cfg", 'AmiId', "${stackParameterMap['AmiId']}", 'Parameters')
        echo "Current ${key}-TPO AMI: ${stackParameterMap['AmiId']}"
    }
}

def enableDisableEnvironment(Map stageParamsMap) {
    jenkinsOps.withUpdateStack {
        def branches = [:]
        stageParamsMap.each { key, value ->
            def currentKey = key
            def currentValue = value
            branches[key] = {
                def subBranches = [:]
                subBranches["BIBE ${currentKey}"] = { jenkinsOps.conditionalStage("BIBE ${currentKey}", currentValue.action != '-', {
                    updateStack("nvs-psx${currentKey}-bibe", "nvs-psx${currentKey}-bibe.cfg", "${currentKey}-bibe")
                })}
                subBranches["TPO ${currentKey}"] = { jenkinsOps.conditionalStage("TPO ${currentKey}", currentValue.action != '-', {
                    updateStack("tpo-psx${currentKey}-appsrv", "tpo-psx${currentKey}-appsrv.cfg", "${currentKey}-tpo")
                })}
                parallel subBranches
            }
        }
        parallel branches
    }
}

def updateStack(String stackName, String configFile, String badgeSuffix) {
    catchError(buildResult: 'UNSTABLE', stageResult: 'FAILURE') {
        def returnStatus = sh(script: "./update-stack_new.py ${configFile}", returnStatus: true)
        if (returnStatus == 0) {
            sh "aws cloudformation wait stack-update-complete --stack-name ${stackName}"
            echo "Stack ${stackName} updated successfully"
        } else if (returnStatus == 3) {
            echo "No update needed for ${stackName}"
            addInfoBadge(text: "No cfn changes for ${badgeSuffix}")
        } else {
            error("CloudFormation update failed for ${stackName}: ${returnStatus}")
        }
    }
}

def addPostInfo(Map stageParamsMap, String configPath) {
    currentBuild.description += '\n\n======================================================\n\nRELEASE CONFIGURATION:\n\n' + jsConfigFile.readConfigFile(configPath)
    jsSoftwareDeployment.addBuildUserBadge()

    def environmentsList = []
    stageParamsMap.each { key, value ->
        if (value.action != '-') {
            environmentsList.add(key.toString().concat(' -> ' + value.action.toString()))
        }
    }
    if (environmentsList.isEmpty()) {
        addWarningBadge(text: 'No Environments chosen!')
    } else {
        addBadge(text: environmentsList.toString())
    }
}
