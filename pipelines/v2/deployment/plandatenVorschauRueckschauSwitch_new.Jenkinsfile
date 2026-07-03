#!groovy
@Library('jenkins') _

properties([

    parameters([
        booleanParam(name: "dryRun", defaultValue: true, description: "Just to load job" ),
        separator(name: "MAIN_PARAM", sectionHeader: "Plandatenauswahl (Vorschau/ Rueckschau)", separatorStyle: "border-width: 3px", sectionHeaderStyle: "background-color: #90ee90"),
        choice(name: 'vr_settings', choices: ['Rueschau','Vorschau'], description: 'Umstellung Vorschau / Rueschau Fahrplan fuer TPO und BiBE'),
        [$class: 'CascadeChoiceParameter',
            choiceType: 'PT_SINGLE_SELECT',
            description: '',
            name: 'connection_review',
            referencedParameters: 'vr_settings',
            script: [$class: 'GroovyScript', fallbackScript: [classpath: [], sandbox: false, script: ''],
            script: [classpath: [], sandbox: false, script: '''
                def filter_proc = "cat /var/jenkins_home/jenkinsDateneinsatzConfig/generated/connection_review_DEFAULT".execute()
                def filter = new StringBuffer()
                def stdout = new StringBuffer()
                def stderr = new StringBuffer()
                filter_proc.waitForProcessOutput(filter, stderr)
                fil = filter.toString().trim()
                def proc = "aws s3 ls s3://556971410989-common-daten/plandaten/connection-review/".execute()
                proc.waitForProcessOutput(stdout, stderr)
                if (vr_settings == 'Rueschau') {
                result = stdout.toString().tokenize().grep(~/\${fil}/).sort().reverse()
                }
                //result.subList(20, result.size()).clear()
                result.add(0,'')
                return result
        ''']]],
        [$class: 'CascadeChoiceParameter',
            choiceType: 'PT_SINGLE_SELECT',
            description: '',
            name: 'connection_preview',
            referencedParameters: 'vr_settings',
            script: [$class: 'GroovyScript', fallbackScript: [classpath: [], sandbox: false, script: ''],
            script: [classpath: [], sandbox: false, script: '''
                def filter_proc = "cat /var/jenkins_home/jenkinsDateneinsatzConfig/generated/connection_preview_DEFAULT".execute()
                def filter = new StringBuffer()
                def stdout = new StringBuffer()
                def stderr = new StringBuffer()
                filter_proc.waitForProcessOutput(filter, stderr)
                fil = filter.toString().trim()
                def proc = "aws s3 ls s3://556971410989-common-daten/plandaten/connection-preview/".execute()
                proc.waitForProcessOutput(stdout, stderr)
                if (vr_settings == 'Vorschau') {
                result = stdout.toString().tokenize().grep(~/\${fil}/).sort().reverse()
                }
                //result.subList(20, result.size()).clear()
                result.add(0,'')
                return result
        ''']]],
        separator(name: "Auswahl_PSX_Umgebungen", sectionHeader: "Auswahl PSX Umgebungen", separatorStyle: "border-width: 3px", sectionHeaderStyle: "background-color: #90ee90"),
        [$class: 'CascadeChoiceParameter',
            choiceType: 'PT_SINGLE_SELECT',
            description: '',
            name: 'env_h',
            referencedParameters: 'vr_settings',
            script: [$class: 'GroovyScript', fallbackScript: [classpath: [], sandbox: false, script: ''],
            script: [classpath: [], sandbox: false, script: '''
                def proc = "cat /var/jenkins_home/jenkinsDateneinsatzConfig/generated/envs_preview".execute()
                def stdout = new StringBuffer()
                def stderr = new StringBuffer()
                proc.waitForProcessOutput(stdout, stderr)
                def envsPreviewList= stdout.toString().trim()
                if ((envsPreviewList.contains('h') && vr_settings == 'Vorschau') || (!envsPreviewList.contains('h') && vr_settings == 'Rueschau')) {
                    return ['-', 'enable_not_recommended']
                }
                return ['-', 'enable']
            ''']]],
        [$class: 'CascadeChoiceParameter',
            choiceType: 'PT_SINGLE_SELECT',
            description: '',
            name: 'env_i',
            referencedParameters: 'vr_settings',
            script: [$class: 'GroovyScript', fallbackScript: [classpath: [], sandbox: false, script: ''],
            script: [classpath: [], sandbox: false, script: '''
                def proc = "cat /var/jenkins_home/jenkinsDateneinsatzConfig/generated/envs_preview".execute()
                def stdout = new StringBuffer()
                def stderr = new StringBuffer()
                proc.waitForProcessOutput(stdout, stderr)
                def envsPreviewList= stdout.toString().trim()
                if ((envsPreviewList.contains('i') && vr_settings == 'Vorschau') || (!envsPreviewList.contains('i') && vr_settings == 'Rueschau')) {
                    return ['-', 'enable_not_recommended']
                }
                return ['-', 'enable']
        ''']]],
        [$class: 'CascadeChoiceParameter',
            choiceType: 'PT_SINGLE_SELECT',
            description: '',
            name: 'env_j',
            referencedParameters: 'vr_settings',
            script: [$class: 'GroovyScript', fallbackScript: [classpath: [], sandbox: false, script: ''],
            script: [classpath: [], sandbox: false, script: '''
                def proc = "cat /var/jenkins_home/jenkinsDateneinsatzConfig/generated/envs_preview".execute()
                def stdout = new StringBuffer()
                def stderr = new StringBuffer()
                proc.waitForProcessOutput(stdout, stderr)
                def envsPreviewList= stdout.toString().trim()
                if ((envsPreviewList.contains('j') && vr_settings == 'Vorschau') || (!envsPreviewList.contains('j') && vr_settings == 'Rueschau')) {
                    return ['-', 'enable_not_recommended']
                }
                return ['-', 'enable']
        ''']]],
        [$class: 'CascadeChoiceParameter',
            choiceType: 'PT_SINGLE_SELECT',
            description: '',
            name: 'env_k',
            referencedParameters: 'vr_settings',
            script: [$class: 'GroovyScript', fallbackScript: [classpath: [], sandbox: false, script: ''],
            script: [classpath: [], sandbox: false, script: '''
                def proc = "cat /var/jenkins_home/jenkinsDateneinsatzConfig/generated/envs_preview".execute()
                def stdout = new StringBuffer()
                def stderr = new StringBuffer()
                proc.waitForProcessOutput(stdout, stderr)
                def envsPreviewList= stdout.toString().trim()
                if ((envsPreviewList.contains('k') && vr_settings == 'Vorschau') || (!envsPreviewList.contains('k') && vr_settings == 'Rueschau')) {
                    return ['-', 'enable_not_recommended']
                }
                return ['-', 'enable']
        ''']]],
        [$class: 'CascadeChoiceParameter',
            choiceType: 'PT_SINGLE_SELECT',
            description: '',
            name: 'env_l',
            referencedParameters: 'vr_settings',
            script: [$class: 'GroovyScript', fallbackScript: [classpath: [], sandbox: false, script: ''],
            script: [classpath: [], sandbox: false, script: '''
                def proc = "cat /var/jenkins_home/jenkinsDateneinsatzConfig/generated/envs_preview".execute()
                def stdout = new StringBuffer()
                def stderr = new StringBuffer()
                proc.waitForProcessOutput(stdout, stderr)
                def envsPreviewList= stdout.toString().trim()
                if ((envsPreviewList.contains('l') && vr_settings == 'Vorschau') || (!envsPreviewList.contains('l') && vr_settings == 'Rueschau')) {
                    return ['-', 'enable_not_recommended']
                }
                return ['-', 'enable']
        ''']]],
        [$class: 'CascadeChoiceParameter',
            choiceType: 'PT_SINGLE_SELECT',
            description: '',
            name: 'env_m',
            referencedParameters: 'vr_settings',
            script: [$class: 'GroovyScript', fallbackScript: [classpath: [], sandbox: false, script: ''],
            script: [classpath: [], sandbox: false, script: '''
                def proc = "cat /var/jenkins_home/jenkinsDateneinsatzConfig/generated/envs_preview".execute()
                def stdout = new StringBuffer()
                def stderr = new StringBuffer()
                proc.waitForProcessOutput(stdout, stderr)
                def envsPreviewList= stdout.toString().trim()
                if ((envsPreviewList.contains('m') && vr_settings == 'Vorschau') || (!envsPreviewList.contains('m') && vr_settings == 'Rueschau')) {
                    return ['-', 'enable_not_recommended']
                }
                return ['-', 'enable']
        ''']]],
        // [$class: 'CascadeChoiceParameter',
        //     choiceType: 'PT_SINGLE_SELECT',
        //     description: '',
        //     name: 'env_n',
        //     referencedParameters: 'vr_settings',
        //     script: [$class: 'GroovyScript', fallbackScript: [classpath: [], sandbox: false, script: ''],
        //     script: [classpath: [], sandbox: false, script: '''
        //         def proc = "cat /var/jenkins_home/jenkinsDateneinsatzConfig/generated/envs_preview".execute()
        //         def stdout = new StringBuffer()
        //         def stderr = new StringBuffer()
        //         proc.waitForProcessOutput(stdout, stderr)
        //         def envsPreviewList= stdout.toString().trim()
        //         if ((envsPreviewList.contains('n') && vr_settings == 'Vorschau') || (!envsPreviewList.contains('n') && vr_settings == 'Rueschau')) {
        //             return ['-', 'enable_not_recommended']
        //         }
        //         return ['-', 'enable']
        // ''']]],
        [$class: 'CascadeChoiceParameter',
            choiceType: 'PT_SINGLE_SELECT',
            description: '',
            name: 'env_q',
            referencedParameters: 'vr_settings',
            script: [$class: 'GroovyScript', fallbackScript: [classpath: [], sandbox: false, script: ''],
            script: [classpath: [], sandbox: false, script: '''
                def proc = "cat /var/jenkins_home/jenkinsDateneinsatzConfig/generated/envs_preview".execute()
                def stdout = new StringBuffer()
                def stderr = new StringBuffer()
                proc.waitForProcessOutput(stdout, stderr)
                def envsPreviewList= stdout.toString().trim()
                if ((envsPreviewList.contains('q') && vr_settings == 'Vorschau') || (!envsPreviewList.contains('q') && vr_settings == 'Rueschau')) {
                    return ['-', 'enable_not_recommended']
                }
                return ['-', 'enable']
        ''']]],
        separator(name: "Auswahl_Aktion", sectionHeader: "Abschnitt Auswahl", separatorStyle: "border-width: 3px", sectionHeaderStyle: "background-color: #90ee90"),
        booleanParam(name: 'pman', defaultValue: true, description: 'Toggle this on if you want to start pman to modify data versions in S3 (csv files) for psx envinroment'),
        booleanParam(name: 'bibe_data_deployment', defaultValue: false, description: 'Toggle this on if you want to start deploying data into bibe psx envinroment, recommend only if data deployment is stable'),
        booleanParam(name: 'tpo_data_deployment', defaultValue: false, description: 'Toggle this on if you want to start deploying data into tpo psx envinroment, recommend only if data deployment is stable'),
        booleanParam(name: 'compare_data', defaultValue: false, description: 'Toggle this on if you want to start comparing actual data packets on bibe and tpo psx envinroment, recommend only if data deployment is stable'),
    ]), [$class: 'RebuildSettings', autoRebuild: false, rebuildDisabled: false]

])

pipeline {
    agent { label jenkinsOps.defaultAgentLabel() }

    stages {

        stage('CLEAR CSV - V/R Plandaten') {
            when {
                expression { !params.dryRun }
            }
            steps{
                script {
                    def environmentList = ['h', 'i', 'j', 'k', 'l', 'm', 'q']
                    def branches = environmentList.collectEntries { environment ->
                        ["Step ${environment}": {
                            if (params["env_${environment}"] == 'enable') {
                                clear_csv("${environment}")
                            } else {
                                echo "Skipping Step for ${environment} due to condition"
                            }
                        }]
                    }
                    paralles branches
                }
            }
        }

        // stage('CLEAR CSV - V/R Plandaten') {
        //     stages {
        // stage('h') {
        //     when {
        //         expression { params.env_h == 'enable' }
        //     }
        //     steps{
        //         clear_csv('h')
        //     }
        // }
        // stage('i') {
        //     when {
        //         expression { params.env_i == 'enable' }
        //     }
        //     steps{
        //         clear_csv('i')
        //     }
        // }
        // stage('j') {
        //     when {
        //         expression { params.env_j == 'enable' }
        //     }
        //     steps{
        //         clear_csv('j')
        //     }
        // }
        // stage('k') {
        //     when {
        //         expression { params.env_k == 'enable' }
        //     }
        //     steps{
        //         clear_csv('k')
        //     }
        // }
        // stage('l') {
        //     when {
        //         expression { params.env_l == 'enable' }
        //     }
        //     steps{
        //         clear_csv('l')
        //     }
        // }
        // stage('m') {
        //     when {
        //         expression { params.env_m == 'enable' }
        //     }
        //     steps{
        //         clear_csv('m')
        //     }
        // }
        // // stage('n') {
        // //     when {
        // //         expression { params.env_n == 'enable' }
        // //     }
        // //     steps{
        // //         clear_csv('n')
        // //     }
        // // }
        // stage('q') {
        //     when {
        //         expression { params.env_q == 'enable' }
        //     }
        //     steps{
        //         clear_csv('q')
        //     }
        // }
        //     }
        // }

        stage('DATENEINSATZ') {
            when {
                expression { params.pman && !params.dryRun }
            }
            steps{
                build job: 'BIBE_TPO_DataDeployment', parameters: [
                    string(name: 'RELEASE', value: ''),
                    string(name: 'nvs_abo_verbund', value: ''),
                    string(name: 'tpo_verbund', value: ''),
                    string(name: 'LTBW', value: ''),
                    string(name: 'LTBW_ABO', value: ''),
                    string(name: 'LTN', value: ''),
                    string(name: 'TWE', value: ''),
                    string(name: 'connection', value: ''),
                    string(name: 'entry', value: ''),
                    string(name: 'poi', value: ''),
                    string(name: 'bhf', value: ''),
                    string(name: 'pakmap', value: ''),
                    string(name: 'adr', value: ''),
                    string(name: 'connection_review', value: params.connection_review),
                    string(name: 'connection_preview', value: params.connection_preview),
                    string(name: 'version', value: ''),
                    string(name: 'EKTR_ENV', value: 'Q'),
                    string(name: 'EKTR_19', value: ''),
                    string(name: 'EKTR_29', value: ''),
                    string(name: 'K90', value: ''),
                    string(name: 'KAM', value: ''),
                    string(name: 'abo_plandaten', value: 'hafaspools-abobibe-psx'),
                    string(name: 'nvs_plandaten', value: 'hafaspools-nvsbibe-psx'),
                    string(name: 'tpo_plandaten', value: 'hafaspools-tpo-psx'),
                    string(name: 'abo_preisdaten', value: ''),
                    string(name: 'nvs_preisdaten', value: ''),
                    string(name: 'tpo_preisdaten', value: ''),
                    string(name: '____stammdaten', value: ''),
                    booleanParam(name: 'pman', value: params.pman),
                    booleanParam(name: 'bibe_data_deployment', value: params.bibe_data_deployment),
                    booleanParam(name: 'tpo_data_deployment', value: params.tpo_data_deployment),
                    booleanParam(name: 'compare_data', value: params.compare_data),
                    booleanParam(name: 'terminate_instances', value: false),
                    string(name: 'env_h', value: params.env_h),
                    string(name: 'env_i', value: params.env_i),
                    string(name: 'env_j', value: params.env_j),
                    string(name: 'env_k', value: params.env_k),
                    string(name: 'env_l', value: params.env_l),
                    string(name: 'env_m', value: params.env_m),
                    string(name: 'env_q', value: params.env_q)
                ]
            }
        }

        stage('UPDATE JENKINS CONFIGURATION') {
            when {
                expression { !params.dryRun }
            }
            stages {
                stage('h') {
                    when {
                        expression { params.env_h == 'enable' }
                    }
                    steps{
                        update_config('h', params.vr_settings)
                    }
                }
                stage('i') {
                    when {
                        expression { params.env_i == 'enable' }
                    }
                    steps{
                        update_config('i', params.vr_settings)
                    }
                }
                stage('j') {
                    when {
                        expression { params.env_j == 'enable' }
                    }
                    steps{
                        update_config('j', params.vr_settings)
                    }
                }
                stage('k') {
                    when {
                        expression { params.env_k == 'enable' }
                    }
                    steps{
                        update_config('k', params.vr_settings)
                    }
                }
                stage('l') {
                    when {
                        expression { params.env_l == 'enable' }
                    }
                    steps{
                        update_config('l', params.vr_settings)
                    }
                }
                stage('m') {
                    when {
                        expression { params.env_m == 'enable' }
                    }
                    steps{
                        update_config('m', params.vr_settings)
                    }
                }
                stage('q') {
                    when {
                        expression { params.env_q == 'enable' }
                    }
                    steps{
                        update_config('q', params.vr_settings)
                    }
                }
            }
        }
    }
}

def clear_csv(psxEnv) {
    catchError {
        dir("hafaspools") {
            //sync psx plandaten csv, remove review/preview records and sync it into S3 again
            sh """
                aws s3 sync s3://556971410989-common-daten/plandaten . --exclude '*' --include hafaspools-*-psx${psxEnv}.csv
                sed -i '/^connection-preview/d' hafaspools-tpo-psx${psxEnv}.csv hafaspools-nvsbibe-psx${psxEnv}.csv hafaspools-abobibe-psx${psxEnv}.csv
                sed -i '/^connection-review/d'  hafaspools-tpo-psx${psxEnv}.csv hafaspools-nvsbibe-psx${psxEnv}.csv hafaspools-abobibe-psx${psxEnv}.csv
                aws s3 sync . s3://556971410989-common-daten/plandaten
                rm -rf hafaspools-*-psx${psxEnv}.csv
            """
        }
    }
}

def update_config(psxEnv, vr_setting) {
    catchError {
        jenkinsOps.withDeploymentScripts {
            sh """
                ./plandatenVorschauRuesckschau_updateConfig.sh \'${vr_setting}\' \'${psxEnv}\'
            """
        }
        //echo the csv to verify
        dir("hafaspools") {
            //sync psx plandaten csv, remove review/preview records and sync it into S3 again
            sh """
                aws s3 sync s3://556971410989-common-daten/plandaten . --exclude '*' --include hafaspools-*-psx${psxEnv}.csv
                cat hafaspools-tpo-psx${psxEnv}.csv
                cat hafaspools-nvsbibe-psx${psxEnv}.csv
                cat hafaspools-abobibe-psx${psxEnv}.csv
                rm -rf hafaspools-*.csv
            """
        }
    }
}