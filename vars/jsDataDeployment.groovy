/**
 * Data-deployment specific shared-library helpers.
 *
 * Keeps large Active Choices parameter definitions and PMAN data maps out of
 * Jenkinsfiles while preserving the generated parameters and execution model.
 */

def psxStageParams() {
    return [
        h: [  ],
        i: [  ],
        j: [  ],
        k: [  ],
        l: [  ],
        m: [  ],
        q: [  ]
    ]
}

def bibeTpoParameters(Map stageParamsMap = psxStageParams()) {
    def datenMap = [
        connection: [ reference: '' ],
        entry: [ reference: 'connection' ],
        poi: [ reference: 'connection' ],
        bhf: [ reference: '' ],
        pakmap: [ reference: 'bhf' ],
        adr: [ reference: '' ],
        'connection-review': [ reference: '' ],
        'connection-preview': [ reference: '' ],
        stammdaten: [ reference: '' ],
    ]

    def relDatenMap = [
        nvs_abo_verbund: [ folder: 'nvs-abo-verbund', prefix: 'VERB', filter_prefix: 'ABOVERB', reference: '', referenceExpression: '""', drop: 0 ],
        tpo_verbund: [ folder: 'nvs-abo-verbund', prefix: 'VERB', filter_prefix: 'TPOVERB',  reference: 'nvs_abo_verbund', referenceExpression: 'nvs_abo_verbund', drop: 7  ],
        LTBW:  [ folder: 'LTBW', prefix: 'LTBW', filter_prefix: 'LTBW', reference: '', referenceExpression: '""', drop: 0 ],
        LTBW_ABO:  [ folder: 'LTBW-ABO', prefix: 'LTBW', filter_prefix: 'LTBW-ABO', reference: 'LTBW', referenceExpression: 'LTBW', drop: 4 ],
        LTN:  [ folder: 'LTN', prefix: 'LTN', filter_prefix: 'LTN', reference: '', referenceExpression: '""', drop: 0 ],
        TWE:  [ folder: 'TWE', prefix: 'TWE', filter_prefix: 'TWE', reference: '', referenceExpression: '""', drop: 0 ],
    ]

    def customParamList = [
        separator(name: "MAIN_PARAM", sectionHeader: "RELEASE Einstellung", separatorStyle: "border-width: 3px", sectionHeaderStyle: "background-color: #90ee90"),
        [$class: 'CascadeChoiceParameter',
            choiceType: 'PT_SINGLE_SELECT',
            description: 'Datenfiltern und eingeschaltete Umgebungen (default) werden entsprechend aktualisiert',
            name: 'RELEASE',
            script: [$class: 'GroovyScript', fallbackScript: [classpath: [], sandbox: false, script: 'return []'],
            script: [classpath: [], sandbox: false, script: '''
                def result = []
                new File( "/var/jenkins_home/jenkinsDateneinsatzConfig/generated/RELEASE" ).eachLine { line ->
                    result.add(line)
                }
                return result
        ''']]],
        separator(name: "Auswahl_Datenversion", sectionHeader: "Auswahl Datenversion für Einsatz", separatorStyle: "border-width: 3px", sectionHeaderStyle: "background-color: #90ee90"),
    ]

    relDatenMap.each { key, value ->
        def referencedParameters = ['RELEASE', value.reference].findAll { it }.join(',')
        def referenceExpression = value.referenceExpression ?: value.reference
        customParamList.add([$class: 'CascadeChoiceParameter',
            choiceType: 'PT_SINGLE_SELECT',
            description: '',
            name: key,
            referencedParameters: referencedParameters,
            script: [$class: 'GroovyScript', fallbackScript: [classpath: [], sandbox: false, script: "return ['FALLBACK_${key}']"],
            script: [classpath: [], sandbox: false, script: """
                def filter = "${value.filter_prefix}"
                def rel_ALTERNATIVE = new File( "/var/jenkins_home/jenkinsDateneinsatzConfig/generated/RELEASE_ALTERNATIVE" ).text.trim()
                def rel_MAINTENANCE = new File( "/var/jenkins_home/jenkinsDateneinsatzConfig/generated/RELEASE_MAINTENANCE" ).text.trim()
                if (RELEASE == rel_ALTERNATIVE) {
                    filter = new File( "/var/jenkins_home/jenkinsDateneinsatzConfig/generated/${value.prefix}_ALTERNATIVE" ).text.trim()
                } else if (RELEASE == rel_MAINTENANCE) {
                    filter = new File( "/var/jenkins_home/jenkinsDateneinsatzConfig/generated/${value.prefix}_MAINTENANCE" ).text.trim()
                } else {
                    filter = new File( "/var/jenkins_home/jenkinsDateneinsatzConfig/generated/${value.prefix}_____DEFAULT" ).text.trim()
                }
                def proc = "aws s3 ls s3://556971410989-common-daten/preisdaten/${value.folder}/${value.filter_prefix}".execute()
                def stdout = new StringBuffer()
                def stderr = new StringBuffer()
                proc.waitForProcessOutput(stdout, stderr)
                result = stdout.toString().tokenize().grep(~/${value.filter_prefix}\${filter}.*.zip/).sort().reverse()
                if (result.size() > 10) {
                    result.subList(9, result.size()).clear()
                }
                result.add(0,'')
                if (${referenceExpression} != '') {
                    def expectedPrefix="${value.filter_prefix}"+${referenceExpression}.drop(${value.drop}).reverse().drop(6).reverse()
                    result.indexed().each { i,v ->
                        if(v.toString().startsWith(expectedPrefix)) {
                                result.add(0,v.toString())
                                return result
                        }
                    }
                }
                return result
        """]]])
    }

    datenMap.each { key, value ->
        def folder = 'plandaten'
        def name = key.replaceAll('-','_')
        if (key == 'pakmap') {
            folder = 'preisdaten'
        }
        folder = "${folder}/${key}"
        if (key == 'stammdaten') {
            folder = key
            name = 'version'
        }
        customParamList.add([$class: 'CascadeChoiceParameter',
            choiceType: 'PT_SINGLE_SELECT',
            description: '',
            referencedParameters: "${value.reference}",
            name: name,
            script: [$class: 'GroovyScript', fallbackScript: [classpath: [], sandbox: false, script: ''],
            script: [classpath: [], sandbox: false, script: """
                def filter = new File( "/var/jenkins_home/jenkinsDateneinsatzConfig/generated/${name}_DEFAULT" ).text.trim()
                def proc = "aws s3 ls s3://556971410989-common-daten/${folder}/".execute()
                def stdout = new StringBuffer()
                def stderr = new StringBuffer()
                proc.waitForProcessOutput(stdout, stderr)
                result = stdout.toString().tokenize().grep(~/\${filter}.*zip/).sort().reverse()
                if (result.size() > 10) {
                    result.subList(9, result.size()).clear()
                }
                result.add(0,'')
                //for entry, poi
                // if ("${value.reference}" == "connection") {
                //     if (connection != '') {
                //         def expectedSuffix = '-v'+connection.substring(0, 3)+'.zip'
                //         def expectedSubstring = (connection - '.zip').takeRight(2) + '_' + connection.substring(0, 3)
                //         result.indexed().each { i,v ->
                //             if(v.toString().endsWith(expectedSuffix) || v.toString().contains(expectedSubstring)) {
                //                 result.add(0,v.toString())
                //             }
                //         }
                //     }
                // }
                //for pakmap
                if ("${value.reference}" == "bhf") {
                    if (bhf != '') {
                        def date = bhf.drop(11).take(9).replaceAll('-','')
                        def expectedPakmap = 'pakmap_'+date+'.zip'
                        result.indexed().each { i,v ->
                            if(v.toString() == expectedPakmap) {
                                result.add(0,expectedPakmap)
                            }
                        }
                    }
                }
                return result
        """]]])
    }

    def customENVCHOICES = []
    stageParamsMap.each { key, value ->
        customENVCHOICES.add(0, key.toUpperCase())
    }

    customParamList.add(choice(name: 'EKTR_ENV', choices: customENVCHOICES, description: "Umgebungsauswahl für konkrete EKTR Pakete - nicht relevant für empty oder latest!"))

    def hadParamsMap = [
        'EKTR_19' : [ folder: 'VL_NPS_EBPB', filter: '_1901001_202' ],
        'EKTR_29' : [ folder: 'VL_NPS_EBPB', filter:'_2901001_202' ],
        'K90' : [ folder: 'VL_NPS_EBPB', filter:'_k90-' ],
        'KAM' : [ folder: 'KAM', filter: '_1901000_202' ]
    ]

    hadParamsMap.each { key, value ->
        def folder = value['folder']
        def filter = value['filter']

        def defaultSelection = (folder == 'KAM')
            ? "result.add(0,''); result.add(0,'latest')"
            : "result.add(0,'latest'); result.add(0,'')"

        customParamList.add([
            $class: 'CascadeChoiceParameter',
            choiceType: 'PT_SINGLE_SELECT',
            description: '',
            name: key,
            referencedParameters: 'EKTR_ENV',
            script: [
                $class: 'GroovyScript',
                fallbackScript: [
                    classpath: [],
                    sandbox: false,
                    script: "return ['FALLBACK_${key}']"
                ],
                script: [
                    classpath: [],
                    sandbox: false,
                    script: """
                        def proc = "aws s3 ls s3://556971410989-common-daten/preisdaten/${folder}/EPA3-\${EKTR_ENV}${filter}".execute()
                        def stdout = new StringBuffer()
                        def stderr = new StringBuffer()

                        proc.waitForProcessOutput(stdout, stderr)

                        result = stdout.toString()
                            .tokenize()
                            .grep(~/.*.tar.bz2/)
                            .sort()
                            .reverse()

                        if (result.size() > 10) {
                            result.subList(9, result.size()).clear()
                        }

                        ${defaultSelection}

                        return result
                    """
                ]
            ]
        ])
    }

    customParamList = customParamList + [
        separator(name: "Auswahl_Application", sectionHeader: "Applikation Auswahl für pman Einsatz (normallerweise ist default Einstellung ausreichend)", separatorStyle: "border-width: 3px", sectionHeaderStyle: "background-color: #90ee90"),
        string(name: 'abo_plandaten', defaultValue: 'hafaspools-abobibe-psx', description: 'empty string = skip application'),
        string(name: 'nvs_plandaten', defaultValue: 'hafaspools-nvsbibe-psx', description: 'empty string = skip application'),
        string(name: 'tpo_plandaten', defaultValue: 'hafaspools-tpo-psx', description: 'empty string = skip application'),
        string(name: 'abo_preisdaten', defaultValue: 'preisdaten-abobibe-psx', description: 'empty string = skip application'),
        string(name: 'nvs_preisdaten', defaultValue: 'preisdaten-nvsbibe-psx', description: 'empty string = skip application'),
        string(name: 'tpo_preisdaten', defaultValue: 'preisdaten-tpo-psx', description: 'empty string = skip application'),
        string(name: '____stammdaten', defaultValue: 'stammdaten-nvsbibe-psx', description: 'empty string = skip application'),
        separator(name: "Auswahl_Aktion", sectionHeader: "Abschnitt Auswahl", separatorStyle: "border-width: 3px", sectionHeaderStyle: "background-color: #90ee90"),
        booleanParam(name: 'pman', defaultValue: true, description: 'Toggle this on if you want start pman to modify data versions in S3 (csv files) for psx envinroment'),
        booleanParam(name: 'bibe_data_deployment', defaultValue: true, description: 'Toggle this on if you want start deploying data into bibe psx envinroment, recommend only if data deployment is stable'),
        booleanParam(name: 'tpo_data_deployment', defaultValue: true, description: 'Toggle this on if you want start deploying data into tpo psx envinroment, recommend only if data deployment is stable'),
        booleanParam(name: 'compare_data', defaultValue: true, description: 'Toggle this on if you want start comparing actual data packets on bibe and tpo psx envinroment, recommend only if data deployment is stable'),
        booleanParam(name: 'terminate_instances', defaultValue: false, description: 'enable to terminate instance instead of reset'),
        separator(name: "Auswahl_PSX_Umgebungen", sectionHeader: "Auswahl PSX Umgebungen", separatorStyle: "border-width: 3px", sectionHeaderStyle: "background-color: #90ee90")
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
    return customParamList
}

def bibeTpoPmanDataMap() {
    return [
        'aboPlandatenMap' : [
            'abo_plandaten' : '',
            'entry' : '',
            'connection' : '',
            'connection_review' : '',
            'connection_preview' : '',
            'bhf' : '',
            'adr' : '',
            'poi' : ''
        ],
        'nvsPlandatenMap' : [
            'nvs_plandaten' : '',
            'entry' : '',
            'connection' : '',
            'connection_preview' : '',
            'bhf' : '',
            'adr' : '',
            'poi' : ''
        ],
        'tpoPlandatenMap' : [
            'tpo_plandaten' : '',
            'connection' : '',
            'connection_preview' : ''
        ],
        'aboPreisdatenMap' : [
            'abo_preisdaten' : '',
            'LTBW_ABO' : '',
            'TWE' : '',
            'nvs_abo_verbund' : '',
            'KAM' : '',
            'EKTR_29' : '',
            'pakmap' : '',
            'LTN' : ''
        ],
        'nvsPreisdatenMap' : [
            'nvs_preisdaten' : '',
            'LTBW' : '',
            'TWE' : '',
            'nvs_abo_verbund' : '',
            'KAM' : '',
            'EKTR_19' : '',
            'pakmap' : '',
            'LTN' : ''
        ],
        'tpoPreisdatenMap' : [
            'tpo_preisdaten' : '',
            'LTBW' : '',
            'TWE' : '',
            'tpo_verbund' : '',
            'K90' : '',
            'KAM' : '',
            'LTN' : ''
        ],
        'stammdatenMap' : [
            '____stammdaten' : '',
            'version' : ''
        ]
    ]
}
