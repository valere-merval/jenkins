#!groovy
import org.jenkinsci.plugins.pipeline.modeldefinition.Utils

def testTypeMap = [
    systemTest: [ instances: [], action: '-' ],
    assemblyTest: [ instances: [], action: '-' ],
    technischerTest: [ instances: [], action: '-' ]
]

def instanceParamMap = [:]

def customParamList = [
    booleanParam(name: "dryRun", defaultValue: false, description: "Just to load job from git" ),
    choice(name: "environment", choices: ['h', 'i', 'j', 'k', 'l', 'm', 'q'], description: "Environment in which to start or stop a test type"),
    separator(name: "bibeTpo_choice", sectionHeader: "Choices for BIBE and TPO", separatorStyle: "border-width: 3px", sectionHeaderStyle: "background-color: #90ee90"),
    choice(name: "onOffEnvironment", choices: ['-', 'on', 'off'], description: "Use onOffEnvironment-JJ to start or stop BIBE and TPO as well"),
    string(name: 'bibeAmi', defaultValue: '', description: 'New Ami to use. Use an empty string for current used ami'),
    string(name: 'tpoAmi', defaultValue: '', description: 'New Ami to use. Use an empty string for current used ami'),
    separator(name: "testType_choice", sectionHeader: "Test type for action", separatorStyle: "border-width: 3px", sectionHeaderStyle: "background-color: #90ee90"),
]

testTypeMap.keySet().each { testType ->
    customParamList.add(choice(name: "${testType}", choices: ['-', 'start', 'stop'], description: "Choose an action for ${testType} as test type"))
}


properties([parameters(customParamList), [$class: 'RebuildSettings', autoRebuild: false, rebuildDisabled: false]])
pipeline {
    agent { label 'master' }

    stages {

        stage('CREATE INSTANCE NAMES AND POPULATE TESTTYPEMAP') {
            when {
                expression { !params.dryRun }
            }
            steps {
                script {

                    testTypeMap.each { testType, entries ->
                        entries.action = params[testType]
                        if ( entries.action != '-') {
                            switch(testType) {
                                case 'systemTest':
                                    entries.instances.add("nvs-psx${params.environment}-pxysrv-st-1")
                                    entries.instances.add("nvs-psx${params.environment}-appsrv-st-1")
                                    break
                                case 'assemblyTest':
                                    entries.instances.add("nvs-psx${params.environment}-pxysrv-at-1")
                                    entries.instances.add("nvs-psx${params.environment}-appsrv-at-1")
                                    break
                                case 'technischerTest':
                                    entries.instances.add("nvs-psx${params.environment}-pxysrv-tt-1")
                                    entries.instances.add("nvs-psx${params.environment}-pxysrv-tt-2")
                                    entries.instances.add("nvs-psx${params.environment}-pxysrv-tt-3")
                                    entries.instances.add("nvs-psx${params.environment}-appsrv-tt-1")
                                    entries.instances.add("nvs-psx${params.environment}-appsrv-tt-2")
                                    entries.instances.add("nvs-psx${params.environment}-appsrv-tt-3")
                                    break
                            }
                        }
                    }

                    testTypeMap.each { testType, entries ->
                        echo "${entries.instances} -> ${entries.action}"
                    }

                }
            }
        }

        stage('GET EC2 PARAMETER') {
            when {
                expression { !params.dryRun }
            }
            steps {
                script {
                    def branches = [:]
                    testTypeMap.each { testType, entries ->
                        // def currentTestType = testType
                        def currentEntries = entries
                        branches[testType] = {
                            def subBranches = [:]
                            if (currentEntries.instances) {
                                currentEntries.instances.each { instance ->
                                    subBranches[instance] = {
                                        instanceParamMap[instance] = getEC2Parameters(instance)
                                    }
                                }
                                parallel subBranches
                            }
                        }
                    }
                    parallel branches
                }
            }
        }

        stage('START/STOP INSTANCES') {
            when {
                expression { !params.dryRun }
            }
            steps {
                script {
                    def branches = [:]
                    testTypeMap.each { testType, entries ->
                        def currentEntries = entries
                        branches[testType] = {
                            def subBranches = [:]
                            if (currentEntries.instances) {
                                currentEntries.instances.each { instance ->
                                    subBranches[instance] = {
                                        changeEC2State(instanceParamMap[instance].instanceId, currentEntries.action, instanceParamMap[instance].state)
                                    }
                                }
                                parallel subBranches
                            }
                        }
                    }
                    parallel branches
                }
            }
        }

        stage('TRIGGER onOffEnvironment JOB') {
            when {
                expression { !params.dryRun && params.onOffEnvironment != '-' }
            }
            steps {
                script {
                    build job: 'onOffEnvironment',
                    wait: true,
                    parameters: [
                        booleanParam(name: "dryRun", value: false),
                        string(name: 'bibeAmi', value: params.bibeAmi),
                        string(name: 'tpoAmi', value: params.tpoAmi),
                        string(name: "env_${environment}", value: params.onOffEnvironment)
                    ]
                }
            }
        }

    }

}

def getEC2Parameters(String instanceName) {

    def json = sh(
        script: """
          aws ec2 describe-instances \
            --filters "Name=instance-state-name,Values=stopped,running" "Name=tag:Name,Values=${instanceName}" \
            --query "Reservations[].Instances[]" \
            --output json
        """,
        returnStdout: true
    ).trim()
    def instance = readJSON text: json

    if (!instance || instance.isEmpty()) {
        error "No EC2 instance found for ${instanceName}"
    }

    def i = instance[0]
    // convert tags into a normal Map
    def tags = i.Tags.collectEntries { tag ->
        [(tag.Key): tag.Value]
    }

    return [
        name        : instanceName,
        instanceId  : i.InstanceId,
        instanceAmi : i.ImageId,
        state       : i.State.Name,
        privateIp   : i.PrivateIpAddress,
        tags        : tags
    ]

}

def changeEC2State(String instanceId, String action, String state) {

    if (!(action in ['start', 'stop'])) {
        error("Unsupported action '${action}'")
    }

    switch (action) {
        case 'start':
            if (state == 'running') {
                echo "Instance ${instanceId} is already running."
                return
            }
            if (state != 'stopped') {
                error("Cannot start instance ${instanceId} while state is '${state}'")
            }
            break
        case 'stop':
            if (state == 'stopped') {
                echo "Instance ${instanceId} is already stopped."
                return
            }
            if (state != 'running') {
                error("Cannot stop instance ${instanceId} while state is '${state}'")
            }
            break
    }

    // echo "${instanceId} has state ${state} and should be ${action}ed"
    sh """
        aws ec2 ${action}-instances --instance-ids ${instanceId}
    """

}
