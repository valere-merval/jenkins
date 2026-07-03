#!groovy
pipeline {
    agent { label 'master' }

    options {
        disableConcurrentBuilds()
    }

    parameters {
        string(name: 'environments', defaultValue: '', description: 'csv list with apps')
    }

    stages {
        stage ('deploy data') {
            steps {
                script {

                    def appList = params.environments.trim().split(',')
                    println 'appList=' + appList
                    for (app in appList) {
                        // stop app
                        // runCommand(app, 'p')
                        // install data
                        // runCommand(app, 'd')
                        // install sw
                        // runCommand(app, 's')
                        // start app
                        // runCommand(app, 't')
                        dir("scripts/deployment") {
                            sshagent(['7f075ad2-e78f-429d-8713-4a6acd5f7dc2']) {
                                sh "./asi.sh -p -a \'${app}\'"
                                sh "./asi.sh -d -a \'${app}\'"
                                sh "./asi.sh -t -a \'${app}\'"
                            }
                        }
                    }

                }
            }
        }
    }
}

def runCommand(app, command) {
    // app -> tpo-psxl-appsrv, nvs-psxl-bibe-hafas-nvs, nvs-psxl-hafas-abo
    // command -> see asi.sh -h
    if (app.contains('tpo') || app.contains('bibe')) {
        def action = ''
        switch (command) {
            case 'p':
                action = 'stop app'
                break
            case 't':
                action = 'start app'
                break
            case 'r':
                action = 'restart app'
                break
            case 'd':
                action = 'install data'
                break
            case 's':
                action = 'install sw'
                break
            default:
                action = 'undef'
        }
        if (action != 'undef') {
            dir("scripts/deployment") {
                // sshagent(['7f075ad2-e78f-429d-8713-4a6acd5f7dc2']) {
                    println "app=" + ${app} + "; action=[" + ${action} + "];"
                    sh "./asi.sh -\'${command}\' -a \'${app}\'"
                // }
            }
        } else {
            println 'Can not execute ' + command + ' on ' + app + '. Command is not known.'
        }
    } else {
        println 'Can not execute ' + command + ' on ' + app + '. App must be tpo or bibe.'
    }
}
