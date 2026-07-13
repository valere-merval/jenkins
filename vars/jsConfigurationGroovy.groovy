/** Shared logic for modifyConfigurationGroovy pipeline. */

def configurationMap() {
    return [
        lists: [
            RELEASE: [values: [], schema: ['20260801', '20260614', '20260401']]
        ],
        strings: [
            ENV_H_RELEASE: [value: '', schema: '20260614'],
            ENV_I_RELEASE: [value: '', schema: '20260614'],
            ENV_J_RELEASE: [value: '', schema: '20260614'],
            ENV_K_RELEASE: [value: '', schema: '20260401'],
            ENV_L_RELEASE: [value: '', schema: '20260614'],
            ENV_M_RELEASE: [value: '', schema: '20260614'],
            ENV_Q_RELEASE: [value: '', schema: '20260401'],
            RELEASE_____DEFAULT: [value: '', schema: '20260801'],
            RELEASE_MAINTENANCE: [value: '', schema: '20260614'],
            RELEASE_ALTERNATIVE: [value: '', schema: '20260401'],
            TWE_____DEFAULT: [value: '', schema: '_REL(0614|0801)'],
            TWE_MAINTENANCE: [value: '', schema: '_REL(0614)'],
            TWE_ALTERNATIVE: [value: '', schema: '_REL(0401|0614)'],
            LTBW_____DEFAULT: [value: '', schema: '_R26(0614|0801)'],
            LTBW_MAINTENANCE: [value: '', schema: '_R26(0614)'],
            LTBW_ALTERNATIVE: [value: '', schema: '_R26(0401|0614)'],
            LTN_____DEFAULT: [value: '', schema: '_R26(0614|0801)'],
            LTN_MAINTENANCE: [value: '', schema: '_R26(0614)'],
            LTN_ALTERNATIVE: [value: '', schema: '_R26(0401|0614)'],
            VERB_____DEFAULT: [value: '', schema: '_R26(0614|0801)_V'],
            VERB_MAINTENANCE: [value: '', schema: '_R26(0614)_V'],
            VERB_ALTERNATIVE: [value: '', schema: '_REL(0614|0801)'],
            bhf_DEFAULT: [value: '', schema: 'bhf-plan-202'],
            entry_DEFAULT: [value: '', schema: 'entry-pool-2'],
            poi_DEFAULT: [value: '', schema: 'poi-pool-2'],
            pakmap_DEFAULT: [value: '', schema: 'pakmap_2'],
            adr_DEFAULT: [value: '', schema: 'adressdaten-20'],
            version_DEFAULT: [value: '', schema: 'FSTD_R2'],
            connection_DEFAULT: [value: '', schema: '0[0-9][0-9]_00[1-2]_BIBE_Plandaten_J26'],
            connection_preview_DEFAULT: [value: '', schema: '0[0-3][0-9]_00[1-3].*_Plandaten_J26'],
            connection_review_DEFAULT: [value: '', schema: '[0-9][0-9][0-9]_00[1-2]_BIBE_Plandaten_J25']
        ],
        pseudoLists: [
            evns_preview: [values: [], schema: ['x', 'h', 'i', 'j', 'k', 'l', 'm', 'q']],
            envs_deactivated: [values: [], schema: ['x', 'h', 'i', 'j', 'k', 'l', 'm', 'q']]
        ]
    ]
}

def parameters(Map configurationMap) {
    def customParamList = [
        booleanParam(name: 'dryRun', defaultValue: false, description: 'Just to load job from git'),
        booleanParam(name: 'createBackup', defaultValue: false, description: 'Toggle to create a backup of the Configuration.groovy'),
        booleanParam(name: 'clearPreviouslycreatedBackups', defaultValue: false, description: 'Toggle to clear old backups. ONLY works when createBackup is set to true!'),
        separator(name: 'configurationParams', sectionHeader: 'Parameter for the Configuration.groovy', separatorStyle: 'border-width: 3px', sectionHeaderStyle: 'background-color: #90ee90'),
    ]

    configurationMap.each { type, entries ->
        switch (type) {
            case 'lists':
            case 'pseudoLists':
                entries.each { parameterName, parameterDefinition ->
                    customParamList.add(string(name: "${parameterName}", defaultValue: '', description: "${parameterDefinition.schema.join(',')}"))
                }
                break
            case 'strings':
                entries.each { parameterName, parameterDefinition ->
                    customParamList.add(string(name: "${parameterName}", defaultValue: '', description: "${parameterDefinition.schema}"))
                }
                break
        }
    }
    return customParamList
}

def populateConfigMap(Map configurationMap, Map values) {
    configurationMap.each { type, entries ->
        switch (type) {
            case 'lists':
            case 'pseudoLists':
                entries.each { parameterName, parameterDefinition ->
                    parameterDefinition.values = values[parameterName] ? values[parameterName].split(',').collect { it.trim() }.findAll { it } : []
                }
                break
            case 'strings':
                entries.each { parameterName, parameterDefinition ->
                    parameterDefinition.value = values[parameterName]
                }
                break
        }
    }
}

def appendConfigDescription(String configPath, String title, Boolean append = false) {
    def description = "${title}\n"
    jsConfigFile.parseConfigFile(configPath).each { key, value ->
        description += "${key}: ${value}\n"
    }
    if (append) {
        currentBuild.description += description
    } else {
        currentBuild.description = description
    }
}

def backupConfig(String configPath, String buildNumber, Boolean clearOldBackups = false) {
    if (clearOldBackups) {
        sh """
            rm -f "${configPath}".bak.*
        """
    }
    sh """
        cp "${configPath}" "${configPath}.bak.${buildNumber}"
    """
}

def applyConfiguration(Map configurationMap, String configPath) {
    configurationMap.each { type, entries ->
        switch (type) {
            case 'lists':
                entries.each { parameterName, parameterDefinition ->
                    if (parameterDefinition.values) {
                        jsConfigFile.modifyListValuesInConfigfile(configPath, parameterName, [], parameterDefinition.values, true)
                        echo "${parameterName} -> ${parameterDefinition.values}"
                    }
                }
                break
            case 'strings':
                entries.each { parameterName, parameterDefinition ->
                    if (parameterDefinition.value) {
                        jsConfigFile.setValueInConfigFile(configPath, parameterName, parameterDefinition.value, null)
                        echo "${parameterName} -> ${parameterDefinition.value}"
                    }
                }
                break
            case 'pseudoLists':
                entries.each { parameterName, parameterDefinition ->
                    if (parameterDefinition.values) {
                        jsConfigFile.modifyPseudoListValuesInConfigfile(configPath, parameterName, [], parameterDefinition.values, true)
                        echo "${parameterName} -> ${parameterDefinition.values}"
                    }
                }
                break
        }
    }
    jsConfigFile.generateFilesFromConfig(configPath)
}
