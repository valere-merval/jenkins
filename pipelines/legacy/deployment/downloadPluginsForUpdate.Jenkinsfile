desc = ""
pipeline {
    agent {
        label 'master'
    }

    options {
        disableConcurrentBuilds()
    }

    environment {
        JENKINS_PLUGINS_FOLDER = '/usr/share/hdm/jenkins/plugins'
    }

    parameters {
        text(name: 'Plugins_Updates', defaultValue:  '', description: 'This is only for test purpose')
        text(name: 'new_dependencies', defaultValue: '''''', description: 'plugin short name and version at each line is expected')
    }

    stages {
        stage('Cleanup'){
            steps {
                script {
                    sh "rm ${WORKSPACE}/* -rf"
                }
            }
        }

        stage('Download Plugins'){
            steps {
                script {
                    sh "mkdir -p ${WORKSPACE}/pluginsUpdateLatest"
                    def plugins = jenkins.model.Jenkins.instance.getPluginManager().getPlugins()
                    //plugins.each {println "${it.getLongName()} - ${it.getShortName()}: ${it.getVersion()}; ${it.getUrl()}"}
                    plugins2update = [:]
                    def inputText = "${params.Plugins_Updates}"
                    lines = inputText.split('\n')
                    state = 'START'
                    lines.each { line ->
                        state = LL_Parser(state, line, plugins, plugins2update)
                        //echo "TRACE: " + state + ": ${line}"
                    }
                    assert(state == 'Plugin_START')
                    def new_dependenciesMap =[:]
                    lines = params.new_dependencies.split('\n')
                    lines.each { line ->
                        echo 'TRACE:' + line
                        if (line.split(' ').size() > 1) {
                            new_dependenciesMap[line.split(' ').first()] = line.split(' ').last()
                        }
                    }
                    echo "${plugins2update}\n------------------------------\n${new_dependenciesMap}"
                    println (createShellScript(plugins2update, JENKINS_PLUGINS_FOLDER, new_dependenciesMap))
                }
            }
        }
    }

    post {
        always {
            script {
                def buildUser = "nightly build"
                wrap([$class: 'BuildUser']) {
                    try {
                        buildUser = BUILD_USER
                    } catch (e) {
                        echo "User not in scope, probably triggered from another job"
                    }
                }
                if (env.manager != null) {
                    manager.addShortText("${buildUser}");
                }
                currentBuild.description = desc
            }
        }
    }
}

def createShellScript(plugins2update, plugins_folder, new_dependencies) {
    def output = ""
    output = "=================================   copy this shell code to execute jenkins update   =================================\n"
    output = output + "======================================================================================================================\n"
    output = output + "mkdir -p plugins_latest backup" + "\n"
    output = output + "#loop for each download links\n"
    plugins2update.each { plugin ->
        output = output + "#-----\n"
        output = output + "wget -O plugins_latest/${plugin.key}.hpi https://bahnhub.tech.rz.db.de/artifactory/jenkins-update/${plugin.key}/${plugin.value}/${plugin.key}.hpi\n"
        output = output + "mv ${plugins_folder}/${plugin.key}.jpi backup/${plugin.key}.jpi\n"
        }
    new_dependencies.each { new_plugin ->
        output = output + "#------------------- !!! NEW  ${new_plugin.key}   !!! --------------------------\n"
        output = output + "wget -O plugins_latest/${new_plugin.key}.hpi https://bahnhub.tech.rz.db.de/artifactory/jenkins-update/${new_plugin.key}/${new_plugin.value}/${new_plugin.key}.hpi\n"
        output = output + "mv ${plugins_folder}/${new_plugin.key}.jpi backup/${new_plugin.key}.jpi || true\n"
        }
    output = output + "======================================================================================================================\n"
    output = output + "======================================================================================================================\n"
    plugins2update.each { plugin ->
        output = output + "/bin/cp -up plugins_latest/${plugin.key}.hpi ${plugins_folder}/${plugin.key}.hpi && chown jenkins:jenkins ${plugins_folder}/${plugin.key}.hpi \n"
    }
    new_dependencies.each { new_plugin ->
        output = output + "/bin/cp -up plugins_latest/${new_plugin.key}.hpi ${plugins_folder}/${new_plugin.key}.hpi && chown jenkins:jenkins ${plugins_folder}/${new_plugin.key}.hpi \n"
    }
    output = output + "\n======================================================================================================================\n"
    output = output + "======================================================================================================================\n"
    return output
}

def downloadPlugin(pluginShortName) {
    fileOperations([fileDownloadOperation(password: '', proxyHost: '', proxyPort: '', targetFileName: "${pluginShortName}", targetLocation: '.', url: "https://bahnhub.tech.rz.db.de/artifactory/list/jenkins-update/${pluginShortName}/latest/${pluginShortName}.hpi", userName: '')])
    // def server = Artifactory.server "bahnhub"
    // def downloadSpec = """{
    //     "files":
    //         [
    //             {
    //                 "pattern": "${pluginShortName}/latest/${pluginShortName}.hpi",
    //                 "recursive": "false",
    //                 "flat" : "false"
    //             }
    //         ]
    // }"""
    // echo "hererereeeeeeeeeeeeee"
    // def buildInfo1 = server.download spec: downloadSpec
}

def LL_Parser (state, line, plugins, plugins2update) {
    //------------------------------------------------------------------------------------------------------------------------------------------------------
    if (state == 'START') {
        //get info about release version, author and last modification
        if (line.startsWith('Released')) {
            state = 'START2'
        }
    //------------------------------------------------------------------------------------------------------------------------------------------------------
    } else if (state == 'START2') {
        //get info about release version, author and last modification
        if (line.startsWith('Installiert')) {
            state = 'Plugin_START'
        }
    //------------------------------------------------------------------------------------------------------------------------------------------------------
    } else if (state == 'Plugin_START') {
        plugins.each {
            //echo ("TRACE:" + line + " -> " + it.getLongName())
            trimmedName = it.getLongName().replaceAll('- Plugin|Plug-In|Plugin|plugin|Jenkins ','').trim()
            if (line == trimmedName) {
                println "======= ${it.getLongName()} ======="

                //downloadPlugin(it.getShortName())
                state = "Plugin_NAME_____${it.getShortName()}"
            }
        }
    //------------------------------------------------------------------------------------------------------------------------------------------------------
    } else if (state.startsWith('Plugin_NAME')) {
        if (line.split("\t").first() ==~ /[0-9]+\.[0-9]+\.?[0-9\-]*/) {
            echo "DEBUG: " + state.split("_____").last() + " ... " + line.split("\t").first()
            plugins2update[state.split("_____").last()] = line.split("\t").first()
            println line.split("\t").first() + ' <--- ' + line.split("\t").last()
            state = 'Plugin_START'
        }
    //------------------------------------------------------------------------------------------------------------------------------------------------------
    } else {
        error("unknown state: " + state)
    }
    return state
}
