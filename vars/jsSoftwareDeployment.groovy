import org.jenkins.pipeline.SoftwareDeploymentSupport

private SoftwareDeploymentSupport support() {
    new SoftwareDeploymentSupport(this)
}

def methodMissing(String name, Object args) {
    support().invokeMethod(name, args)
}
