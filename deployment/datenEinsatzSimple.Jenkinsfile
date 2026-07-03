#!groovy
pipeline {
    agent { label 'master' }

    options {
        disableConcurrentBuilds()
    }

    parameters {
        string(name: 'environments', defaultValue: 'REQUIRED_default_not_accepted', description: '')
        string(name: 'packages', defaultValue: 'REQUIRED_default_not_accepted', description: '')
        booleanParam(name: 'run_pipeline', defaultValue: false, description: '')
    }

    stages {
        stage('Daten Einsatz') {
            steps{
                script {
                def envRawList = params.environments.trim().split("\\s*,\\s*")
                def PackageList = params.packages.trim().split("\\s*,\\s*")
                def applicationMatrix = parseEnviroment(envRawList)
                runDatenEinsatzLoop (applicationMatrix, PackageList, params.run_pipeline)
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
            applicationMatrix[envRaw.substring(4,8)]['abo'] = true
        } else if (envRaw =~ /nvs-psx.-bibe-hafas-nvs/) {
            applicationMatrix[envRaw.substring(4,8)]['nvs'] = true
        } else if (envRaw =~ /nvs-psx.-bibe-hafas/) {
            applicationMatrix[envRaw.substring(4,8)]['abo'] = true
            applicationMatrix[envRaw.substring(4,8)]['nvs'] = true
        } else if (envRaw =~ /tpo-psx.*/) {
            applicationMatrix[envRaw.substring(4,8)]['tpo'] = true
        } else {
            error("unsupported psx instance: ${envRaw}")
        }
    }
    return applicationMatrix
}
def runDatenEinsatzLoop(applicationMatrix, PackageList, run_pipeline) {
    echo "DEBUG: applicationMatrix: ${applicationMatrix}"
    echo "DEBUG: PackageList: ${PackageList}"
    def connection = ''
    def entry = ''
    def poi = ''
    def nvs_abo_verbund = ''
    def tpo_verbund = ''
    def twe = ''
    def ltbw = ''
    def pia = ''
    def ltn = ''
    def bhf = ''
    def pakmap = ''
    def version = ''
    def adr = ''
    //def connection_review = ''
    //def connection_preview = ''
    //EKTR_19 = ''
    //EKTR_29 = ''
    //K90 = ''
    //!!!KAM = ''
    PackageList.each { pkg ->
        if (pkg =~ /_001_BIBE_Plandaten_J.*zip/) {
            connection = pkg
        } else if (pkg =~ /entry-pool-2.*zip/) {
            entry = pkg
        } else if (pkg =~ /poi-pool-2.*zip/) {
            poi = pkg
        } else if (pkg =~ /ABOVERB_R.*zip/) {
            nvs_abo_verbund = pkg
        } else if (pkg =~ /TPOVERB_R.*zip/) {
            tpo_verbund = pkg
        } else if (pkg =~ /TWE_REL.*zip/) {
            twe = pkg
        } else if (pkg =~ /LTBW_R2.*zip/) {
            ltbw = pkg
        } else if (pkg =~ /PIA_HDB_REL.*zip/) {
            pia = pkg
        } else if (pkg =~ /LTN_R2.*zip/) {
            ltn = pkg
        } else if (pkg =~ /bhf-plan-20.*-nrw3-neu.zip/) {
            bhf = pkg
        } else if (pkg =~ /pakmap_.*.zip/) {
            pakmap = pkg
        } else if (pkg =~ /R.*-BD.zip/) {
            version = pkg
        } else if (pkg =~ /adressdaten-2.*zip/) {
            adr = pkg
        } else {
            error("unsupported data package: ${pkg}")
        }
    }

    def run_all = false
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
    applicationMatrix.each { env, value ->
        if (value['abo'] && value['nvs'] && value['tpo']) {
            run_all = true
            env_matrix[env] = 'enable'
        } else if (value['abo'] || value['nvs'] || value['tpo']){
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
            run_DatenEinsatz_pipeline(run_pipeline, value['abo'], value['nvs'], value['tpo'], env_matrix_temp, 
            connection, entry, poi, nvs_abo_verbund, tpo_verbund, twe, ltbw, pia, ltn, bhf, pakmap, version, adr)
        }
    }
    if (run_all) {
        run_DatenEinsatz_pipeline(run_pipeline, true, true, true, env_matrix,
        connection, entry, poi, nvs_abo_verbund, tpo_verbund, twe, ltbw, pia, ltn, bhf, pakmap, version, adr)
    }
}

def run_DatenEinsatz_pipeline(run_pipeline, abo, nvs, tpo, env_matrix, 
    connection, entry, poi, nvs_abo_verbund, tpo_verbund, twe, ltbw, pia, ltn, bhf, pakmap, version, adr) {
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
    echo "DEBUG: ======================     run Dateneinsatz     =========================\n \
${env_matrix}\n \
abo=${abo}; nvs=${nvs}; tpo=${tpo}; abo_plandaten={abo_plandaten}; nvs_plandaten={nvs_plandaten} \
tpo_plandaten=${tpo_plandaten}; abo_preisdaten=${abo_preisdaten}; nvs_preisdaten=${nvs_preisdaten}; tpo_preisdaten=${tpo_preisdaten}\n \
connection=${connection}; entry=${entry}; poi=${poi}; \
nvs_abo_verbund=${nvs_abo_verbund}; tpo_verbund=${tpo_verbund}; twe=${twe}; ltbw=${ltbw}; \
pia=${pia}; ltn=${ltn}; bhf=${bhf}; pakmap=${pakmap}; version=${version}; adr=${adr}\n \
DEBUG: ========================================================================="
    if (run_pipeline) {
    build job: 'DataDeployment', parameters: [
        booleanParam(name: 'pman_explicit', value: true) ,
        booleanParam(name: 'tpo_data_deployment', value: true) ,
        booleanParam(name: 'bibe_data_deployment', value: true) ,
        booleanParam(name: 'compare_data', value: true),

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