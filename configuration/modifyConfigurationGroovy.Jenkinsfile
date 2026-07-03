#!groovy
import org.jenkinsci.plugins.pipeline.modeldefinition.Utils


def configurationMap = [
    lists: [ 
        RELEASE: [ values: [], schema: [ '20260801','20260614','20260401' ] ]
    ],
    strings: [
        ENV_H_RELEASE: [ value: '', schema: '20260614' ],
        ENV_I_RELEASE: [ value: '', schema: '20260614' ],
        ENV_J_RELEASE: [ value: '', schema: '20260614' ],
        ENV_K_RELEASE: [ value: '', schema: '20260401' ],
        ENV_L_RELEASE: [ value: '', schema: '20260614' ],
        ENV_M_RELEASE: [ value: '', schema: '20260614' ],
        ENV_Q_RELEASE: [ value: '', schema: '20260401' ],
        RELEASE_____DEFAULT: [ value: '', schema: '20260801' ],
        RELEASE_MAINTENANCE: [ value: '', schema: '20260614' ],
        RELEASE_ALTERNATIVE: [ value: '', schema: '20260401' ],
        TWE_____DEFAULT: [ value: '', schema: '_REL(0614|0801)' ],
        TWE_MAINTENANCE: [ value: '', schema: '_REL(0614)' ],
        TWE_ALTERNATIVE: [ value: '', schema: '_REL(0401|0614)' ],
        LTBW_____DEFAULT: [ value: '', schema: '_R26(0614|0801)' ],
        LTBW_MAINTENANCE: [ value: '', schema: '_R26(0614)' ],
        LTBW_ALTERNATIVE: [ value: '', schema: '_R26(0401|0614)' ],
        LTN_____DEFAULT: [ value: '', schema: '_R26(0614|0801)' ],
        LTN_MAINTENANCE: [ value: '', schema: '_R26(0614)' ],
        LTN_ALTERNATIVE: [ value: '', schema: '_R26(0401|0614)' ],
        VERB_____DEFAULT: [ value: '', schema: '_R26(0614|0801)_V' ],
        VERB_MAINTENANCE: [ value: '', schema: '_R26(0614)_V' ],
        VERB_ALTERNATIVE: [ value: '', schema: '_REL(0614|0801)' ],
        bhf_DEFAULT: [ value: '', schema: 'bhf-plan-202' ],
        entry_DEFAULT: [ value: '', schema: 'entry-pool-2' ],
        poi_DEFAULT: [ value: '', schema: 'poi-pool-2' ],
        pakmap_DEFAULT: [ value: '', schema: 'pakmap_2' ],
        adr_DEFAULT: [ value: '', schema: 'adressdaten-20' ],
        version_DEFAULT: [ value: '', schema: 'FSTD_R2' ],
        connection_DEFAULT: [ value: '', schema: '0[0-9][0-9]_00[1-2]_BIBE_Plandaten_J26' ],
        connection_preview_DEFAULT: [ value: '', schema: '0[0-3][0-9]_00[1-3].*_Plandaten_J26' ],
        connection_review_DEFAULT: [ value: '', schema: '[0-9][0-9][0-9]_00[1-2]_BIBE_Plandaten_J25' ]
    ],
    pseudoLists: [
        evns_preview: [ values: [], schema: ['x','h', 'i', 'j', 'k', 'l', 'm', 'q'] ],
        envs_deactivated: [ values: [], schema: ['x','h', 'i', 'j', 'k', 'l', 'm', 'q'] ]
    ]
]

def customParamList = [
    booleanParam(name: "dryRun", defaultValue: false, description: "Just to load job from git" ),
    booleanParam(name: "createBackup", defaultValue: false, description: "Toggle to create a backup of the Configuration.groovy" ),
    booleanParam(name: "clearPreviouslycreatedBackups", defaultValue: false, description: "Toggle to clear old backups. ONLY works when createBackup is set to true!"),
    separator(name: "configurationParams", sectionHeader: "Parameter for the Configuration.groovy", separatorStyle: "border-width: 3px", sectionHeaderStyle: "background-color: #90ee90"),
]

configurationMap.each { type, entries ->
    switch (type) {
        case 'lists':
            entries.each { parameterName, parameterDefinition ->
                customParamList.add(string(name: "${parameterName}", defaultValue: '', description: "${parameterDefinition.schema.join(',')}"))
            }
            break
        case 'strings':
            entries.each { parameterName, parameterDefinition ->
                customParamList.add(string(name: "${parameterName}", defaultValue: '', description: "${parameterDefinition.schema}"))
            }
            break
        case 'pseudoLists':
            entries.each { parameterName, parameterDefinition ->
                customParamList.add(string(name: "${parameterName}", defaultValue: '', description: "${parameterDefinition.schema.join(',')}"))
            }
            break
    }   
}


properties([parameters(customParamList), [$class: 'RebuildSettings', autoRebuild: false, rebuildDisabled: false]])
pipeline {
    agent { label 'master' }
    environment {
        CONFIG_PATH = "/var/jenkins_home/jenkinsDateneinsatzConfig/Configuration.groovy"
        // CONFIG_PATH = "/var/jenkins_home/jenkinsDateneinsatzConfig/Configuration_test.groovy"
    }

    stages {

        stage('POPULATE CONFIGMAP') {
            when {
                expression { !params.dryRun }
            }
            steps {
                script {
                    configurationMap.each { type, entries ->
                        switch (type) {
                            case 'lists':
                                entries.each { parameterName, parameterDefinition ->
                                    parameterDefinition.values = params[parameterName] ? params[parameterName].split(',').collect{ it.trim() }.findAll{ it } : []
                                    // echo "${parameterDefinition.values}"
                                }
                                break
                            case 'strings':
                                entries.each { parameterName, parameterDefinition ->
                                    parameterDefinition.value = params[parameterName]
                                    // echo "${parameterDefinition.value}"
                                }
                                break
                            case 'pseudoLists':
                                entries.each { parameterName, parameterDefinition ->
                                    parameterDefinition.values = params[parameterName] ? params[parameterName].split(',').collect{ it.trim() }.findAll{ it } : [] 
                                    // echo "${parameterDefinition.values}"
                                }
                                break
                        } 
                    }
                }
            }
        }

        stage('PARSE CURRENT CONFIG') {
            when {
                expression { !params.dryRun }
            }
            steps {
                script {
                    def description = "Old Configuration.groovy:\n"
                    def config = parseConfigFile(env.CONFIG_PATH)
                    config.each{ key, value ->
                        description += "${key}: ${value}\n"
                    }
                    currentBuild.description = description
                }
            }
        }

        stage('CREATE CONFIG BACKUP') {
            when {
                expression { !params.dryRun && params.createBackup }
            }
            steps {
                script {

                    // def configFile = new File(env.CONFIG_PATH)
                    // def backupPath = "${env.CONFIG_PATH}.bak.${env.BUILD_NUMBER}"
                    
                    if (params.clearPreviouslycreatedBackups) {
                        // dir(configFile.parent) {
                            sh """
                                rm -f "${env.CONFIG_PATH}".bak.*
                            """
                        // }
                    }

                    sh """
                        cp "${env.CONFIG_PATH}" "${env.CONFIG_PATH}.bak.${env.BUILD_NUMBER}"
                    """

                }
            }
        }

        stage('CHANGE CONFIG AND GENERATE FILES') {
            when {
                expression { !params.dryRun }
            }
            steps {
                script {
                    configurationMap.each { type, entries ->
                        switch (type) {
                            case 'lists':
                                entries.each { parameterName, parameterDefinition ->
                                    if (parameterDefinition.values) {
                                        modifyListValuesInConfigfile(env.CONFIG_PATH, parameterName, [], parameterDefinition.values, true)
                                        echo "${parameterName} -> ${parameterDefinition.values}"
                                    }
                                }
                                break
                            case 'strings':
                                entries.each { parameterName, parameterDefinition ->
                                    if (parameterDefinition.value) {
                                        setValueInConfigFile(env.CONFIG_PATH, parameterName, parameterDefinition.value, null)
                                        echo "${parameterName} -> ${parameterDefinition.value}"
                                    }
                                }
                                break
                            case 'pseudoLists':
                                entries.each { parameterName, parameterDefinition ->
                                    if (parameterDefinition.values) {
                                        modifyPseudoListValuesInConfigfile(env.CONFIG_PATH, parameterName, [], parameterDefinition.values, true)
                                        echo "${parameterName} -> ${parameterDefinition.values}"
                                    }
                                }
                                break
                        }
                    }
                    generateFilesFromConfig(env.CONFIG_PATH) 
                }
            }
        }

        stage('PARSE NEW CONFIG') {
            when {
                expression { !params.dryRun }
            }
            steps {
                script {
                    def description = "\nNEW Configuration.groovy:\n"
                    def config = parseConfigFile(env.CONFIG_PATH)
                    config.each{ key, value ->
                        description += "${key}: ${value}\n"
                    }
                    currentBuild.description += description
                }
            }
        }

    }
}


def parseConfigFile(String configPath) {

    def configFile = new File(configPath)
    if (!configFile.exists()) error "File ${configPath} not found!"

    def config = [:]
    def currentSection = null

    configFile.readLines().each { line ->    
        line = line.trim()
        // for blank lines and comments
        if (!line || line.startsWith("//") || line.startsWith("#")) { return line }
        // for sections
        if (line.startsWith("[") && line.endsWith("]")) {
            currentSection = line[1..-2].trim()
            if (!config.containsKey(currentSection)) {
                config[currentSection] = [:]
            }
            return line
        }
        // for key-value pairs
        if (line.contains("=") || line.contains(":")) {
            def (key, value) = line.split(/[:=]/, 2).collect { it.trim() }
            // def (key, value) = line.split(/[:=]/, 2)*.trim()
            if (currentSection) {
                config[currentSection][key] = value
            } else {
                config[key] = value
            }
        }
    }

    return config

}

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

def modifyListValuesInConfigfile(String configPath, String key, List valuesToRemove = [], List valuesToAdd = [], Boolean clearFirst = false) {

    def configFile = new File(configPath)
    if (!configFile.exists()) error "File ${configPath} not found!"

    def lines = configFile.readLines()

    def newLines = lines.collect { line ->

        def separatorIndex = line.indexOf("=")
        if (separatorIndex > 0) {

            def keyPart = line[0..(separatorIndex-1)].trim()
            if (keyPart == key) {

                def values = []
                def (k, valuePart) = line.split("=", 2).collect { it.trim() }
                
                if (!clearFirst) {
                    values = valuePart.replaceAll(/\[|\]/, '')
                                    .split(",")
                                    .collect { it.trim().replaceAll('"', '') }
                                    .findAll { it }
                    values = values.findAll { !valuesToRemove.contains(it) }
                }

                values.addAll(valuesToAdd)
                values = values.unique()

                return "${k}=[${values.collect { "\"${it}\"" }.join(',')}]"
            }

        }

        return line
    }

    configFile.setText(newLines.join("\n") + "\n")

}

def modifyPseudoListValuesInConfigfile(String configPath, String key, List valuesToRemove = [], List valuesToAdd = [], Boolean clearFirst = false) {
    
    def configFile = new File(configPath)
    if (!configFile.exists()) error "File ${configPath} not found!"

    def lines = configFile.readLines()

    def newLines = lines.collect { line ->
        line = line.trim()
        if (line.startsWith(key)) {
            
            def values = []
            def (k, valuePart) = line.split("=", 2).collect { it.trim() }

            if (!clearFirst) {
            values = valuePart.replaceAll(/^"|"$/, '')
                            .split("\\|")
                            .collect { it.trim() }
                            .findAll { !valuesToRemove.contains(it) }
            }

            values.addAll(valuesToAdd)
            values = values.unique()

            return "${k}=\"${values.join('|')}\""
        } else {
            return line
        }
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
