/**
 * AWS related helpers for Jenkins pipelines.
 * These wrappers make future migration to AWS credentials binding/JCasC easier.
 */

def cloudFormationParameters(String stackName) {
    if (!stackName?.trim()) {
        error('cloudFormationParameters requires a stack name')
    }
    String output = sh(
        script: "aws cloudformation describe-stacks --stack-name ${shellQuote(stackName)} --query 'Stacks[0].Parameters' --output json",
        returnStdout: true
    ).trim()
    return readJSON(text: output).collectEntries { item -> [(item.ParameterKey): item.ParameterValue] }
}

def ec2InstancesByName(String name) {
    if (!name?.trim()) {
        error('ec2InstancesByName requires a Name tag')
    }
    String output = sh(
        script: "aws ec2 describe-instances --filters Name=tag:Name,Values=${shellQuote(name)} --output json",
        returnStdout: true
    ).trim()
    return readJSON(text: output)
}

def shellQuote(String value) {
    return "'" + value.replace("'", "'\\''") + "'"
}
