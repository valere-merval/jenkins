import org.jenkins.pipeline.DeploymentSupport

private DeploymentSupport support() {
    new DeploymentSupport(this)
}

def methodMissing(String name, Object args) {
    support().invokeMethod(name, args)
}
