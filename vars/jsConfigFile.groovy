/** File/config helpers used by configuration and environment-control pipelines. */

def readConfigFile(String configPath = '/var/jenkins_home/jenkinsDateneinsatzConfig/Configuration.groovy') {
    return sh(script: "cat ${jenkinsOps.shellQuote(configPath)}", returnStdout: true)
}

def parseConfigFile(String configPath) {
    def configFile = new File(configPath)
    if (!configFile.exists()) error "File ${configPath} not found!"

    def config = [:]
    def currentSection = null

    configFile.readLines().each { line ->
        line = line.trim()
        if (!line || line.startsWith('//') || line.startsWith('#')) { return line }
        if (line.startsWith('[') && line.endsWith(']')) {
            currentSection = line[1..-2].trim()
            if (!config.containsKey(currentSection)) {
                config[currentSection] = [:]
            }
            return line
        }
        if (line.contains('=') || line.contains(':')) {
            def (key, value) = line.split(/[:=]/, 2).collect { it.trim() }
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
        if (!line || line.startsWith('//') || line.startsWith('#')) { return line }
        if (line.startsWith('[') && line.endsWith(']')) {
            inSection = (line[1..-2].trim() == section)
            return line
        }
        if (inSection) {
            def separatorIndex = line.indexOf(':')
            if (separatorIndex < 0) { separatorIndex = line.indexOf('=') }
            if ((separatorIndex > 0) && (separatorIndex < line.length() - 1)) {
                def keyPart = line[0..(separatorIndex - 1)].trim()
                def separator = line[separatorIndex]
                def valuePart = line[(separatorIndex + 1)..-1].trim()
                if (keyPart == key) {
                    if ((valuePart.startsWith("'") && valuePart.endsWith("'")) || (valuePart.startsWith('"') && valuePart.endsWith('"'))) {
                        return "${key}${separator}${valuePart[0]}${newValue}${valuePart[-1]}"
                    }
                    return "${key}${separator} ${newValue}"
                }
            }
        }
        return line
    }

    configFile.setText(newLines.join('\n') + '\n')
}

def modifyPseudoListValuesInConfigfile(String configPath, String key, List valuesToRemove = [], List valuesToAdd = [], Boolean clearFirst = false) {
    def configFile = new File(configPath)
    if (!configFile.exists()) error "File ${configPath} not found!"

    def lines = configFile.readLines()
    def newLines = lines.collect { line ->
        line = line.trim()
        if (line.startsWith(key)) {
            def (k, valuePart) = line.split('=', 2).collect { it.trim() }
            def values = []
            if (!clearFirst) {
                values = valuePart.replaceAll(/^"|"$/, '')
                    .split('\\|')
                    .collect { it.trim() }
                    .findAll { !valuesToRemove.contains(it) }
            }

            values.addAll(valuesToAdd)
            values = values.unique()
            return "${k}=\"${values.join('|')}\""
        }
        return line
    }

    configFile.setText(newLines.join('\n') + '\n')
}

def modifyListValuesInConfigfile(String configPath, String key, List valuesToRemove = [], List valuesToAdd = [], Boolean clearFirst = false) {
    def configFile = new File(configPath)
    if (!configFile.exists()) error "File ${configPath} not found!"

    def lines = configFile.readLines()
    def newLines = lines.collect { line ->
        if (line.trim().startsWith("${key}=")) {
            def (k, valuePart) = line.split('=', 2).collect { it.trim() }
            def values = []
            if (!clearFirst) {
                values = valuePart
                    .replaceAll(/\[|\]/, '')
                    .split(',')
                    .collect { it.trim().replaceAll('"', '') }
                    .findAll { it }
                    .findAll { !valuesToRemove.contains(it) }
            }

            values.addAll(valuesToAdd)
            values = values.unique()
            return "${k}=[${values.collect { "\"${it}\"" }.join(', ')}]"
        }
        return line
    }

    configFile.setText(newLines.join('\n') + '\n')
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

def stackParameters(String stackName) {
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
    return params.collectEntries { p -> [(p.ParameterKey): p.ParameterValue] }
}
