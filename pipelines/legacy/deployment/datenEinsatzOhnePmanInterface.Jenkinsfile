#!groovy
pipeline {
    agent { label 'master' }

    options {
        disableConcurrentBuilds()
    }

    parameters {
        string(name: 'environments', defaultValue: 'REQUIRED_default_not_accepted', description: '')
    }

    stages {
        stage('Daten Einsatz') {
            steps {
                script {
                    def envRawList = params.environments.trim().split("\\s*,\\s*")
                    def applicationMatrix = parseEnviroment(envRawList)
                    runDatenEinsatzLoop (applicationMatrix)
                }
            }
        }
    }
}

def parseEnviroment(envRawList) {

    def applicationMatrix = [
        psxh: [abo: false, nvs: false, tpo: false ],
        psxi: [abo: false, nvs: false, tpo: false ],
        psxj: [abo: false, nvs: false, tpo: false ],
        psxk: [abo: false, nvs: false, tpo: false ],
        psxl: [abo: false, nvs: false, tpo: false ],
        psxm: [abo: false, nvs: false, tpo: false ],
        psxn: [abo: false, nvs: false, tpo: false ],
        psxq: [abo: false, nvs: false, tpo: false ]
    ]

    envRawList.each { envRaw ->
        if (envRaw =~ /nvs-psx.-bibe-hafas-abo/) {
            applicationMatrix[envRaw.substring(4, 8)]['abo'] = true
        } else if (envRaw =~ /nvs-psx.-bibe-hafas-nvs/) {
            applicationMatrix[envRaw.substring(4, 8)]['nvs'] = true
        } else if (envRaw =~ /nvs-psx.-bibe-hafas/) {
            applicationMatrix[envRaw.substring(4, 8)]['abo'] = true
            applicationMatrix[envRaw.substring(4, 8)]['nvs'] = true
        } else if (envRaw =~ /tpo-psx.*/) {
            applicationMatrix[envRaw.substring(4, 8)]['tpo'] = true
        } else {
            error("unsupported psx instance: ${envRaw}")
        }
    }
    return applicationMatrix
}

def runDatenEinsatzLoop(applicationMatrix) {

    def env_matrix = [
        psxh: '-',
        psxi: '-',
        psxj: '-',
        psxk: '-',
        psxl: '-',
        psxm: '-',
        psxn: '-',
        psxq: '-'
    ]

    def run_all = false

    applicationMatrix.each { env, value ->
        if (value['abo'] && value['nvs'] && value['tpo']) {
            run_all = true
            env_matrix[env] = 'enable'
        } else if (value['abo'] || value['nvs'] || value['tpo']) {
            def env_matrix_temp = [
                psxh: '-',
                psxi: '-',
                psxj: '-',
                psxk: '-',
                psxl: '-',
                psxm: '-',
                psxn: '-',
                psxq: '-'
            ]
            env_matrix_temp[env] = 'enable'
            run_DatenEinsatz_pipeline(value['abo'], value['nvs'], value['tpo'], env_matrix_temp)
        }
    }
    if (run_all) {
        run_DatenEinsatz_pipeline(true, true, true, env_matrix)
    }
}

def run_DatenEinsatz_pipeline(abo, nvs, tpo, env_matrix) {

    def abo_plandaten = 'hafaspools-abobibe-psx'
    def nvs_plandaten = 'hafaspools-nvsbibe-psx'
    def tpo_plandaten = 'hafaspools-tpo-psx'
    def abo_preisdaten = 'preisdaten-abobibe-psx'
    def nvs_preisdaten = 'preisdaten-nvsbibe-psx'
    def tpo_preisdaten = 'preisdaten-tpo-psx'
    if ( !abo ) {
        abo_plandaten = ''
        abo_preisdaten = ''
    }
    if ( !nvs ) {
        nvs_plandaten = ''
        nvs_preisdaten = ''
    }
    if ( !tpo ) {
        tpo_plandaten = ''
        tpo_preisdaten = ''
    }

    def pman_explicit = false
    def tpo_data_deployment = true
    def bibe_data_deployment = true
    def compare_data = true


    println 'DEBUG: ======================     run Dateneinsatz     ========================='
    println "Reboot of ${params.environments}"

    println "Call pipeline DataDeployment with parameter:"
    println "********************************************"
    println "pman_explicit = ${pman_explicit}"
    println "tpo_data_deployment = ${tpo_data_deployment}"
    println "bibe_data_deployment = ${bibe_data_deployment}"
    println "compare_data = ${compare_data}"

    println "abo_plandaten = ${abo_plandaten}"
    println "nvs_plandaten = ${nvs_plandaten}"
    println "tpo_plandaten = ${tpo_plandaten}"
    println "abo_preisdaten = ${abo_preisdaten}"
    println "nvs_preisdaten = ${nvs_preisdaten}"
    println "tpo_preisdaten = ${tpo_preisdaten}"

    println "env_h = ${env_matrix['psxh']}"
    println "env_i = ${env_matrix['psxi']}"
    println "env_j = ${env_matrix['psxj']}"
    println "env_k = ${env_matrix['psxk']}"
    println "env_l = ${env_matrix['psxl']}"
    println "env_m = ${env_matrix['psxm']}"
    println "env_n = ${env_matrix['psxn']}"
    println "env_q = ${env_matrix['psxq']}"
    println "connection = ${connection}"
    println "entry = ${entry}"
    println "poi = ${poi}"
    println "nvs_abo_verbund = ${nvs_abo_verbund}"
    println "tpo_verbund = ${tpo_verbund}"
    println "twe = ${twe}"
    println "ltbw = ${ltbw}"
    println "pia = ${pia}"
    println "ltn = ${ltn}"
    println "bhf = ${bhf}"
    println "pakmap = ${pakmap}"
    println "version = ${version}"
    println "adr = ${adr}"
    println "********************************************"

    if (true) {

        build job: 'DataDeployment', parameters: [
        booleanParam(name: 'pman_explicit', value: pman_explicit),
        booleanParam(name: 'tpo_data_deployment', value: tpo_data_deployment),
        booleanParam(name: 'bibe_data_deployment', value: bibe_data_deployment),
        booleanParam(name: 'compare_data', value: compare_data),

        string(name: 'abo_plandaten', value: abo_plandaten),
        string(name: 'nvs_plandaten', value: nvs_plandaten),
        string(name: 'tpo_plandaten', value: tpo_plandaten),
        string(name: 'abo_preisdaten', value: abo_preisdaten),
        string(name: 'nvs_preisdaten', value: nvs_preisdaten),
        string(name: 'tpo_preisdaten', value: tpo_preisdaten),

        string(name: 'env_h', value: env_matrix['psxh']),
        string(name: 'env_i', value: env_matrix['psxi']),
        string(name: 'env_j', value: env_matrix['psxj']),
        string(name: 'env_k', value: env_matrix['psxk']),
        string(name: 'env_l', value: env_matrix['psxl']),
        string(name: 'env_m', value: env_matrix['psxm']),
        string(name: 'env_n', value: env_matrix['psxn']),
        string(name: 'env_q', value: env_matrix['psxq']),
        string(name: 'connection', value: connection),
        string(name: 'entry', value: entry),
        string(name: 'poi', value: poi),
        string(name: 'nvs_abo_verbund', value: nvs_abo_verbund),
        string(name: 'tpo_verbund', value: tpo_verbund),
        string(name: 'twe', value: twe),
        string(name: 'ltbw', value: ltbw),
        string(name: 'pia', value: pia),
        string(name: 'ltn', value: ltn),
        string(name: 'bhf', value: bhf),
        string(name: 'pakmap', value: pakmap),
        string(name: 'version', value: version),
        string(name: 'adr', value: adr)
        ]
    }
}
