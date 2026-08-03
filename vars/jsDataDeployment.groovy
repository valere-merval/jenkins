import org.jenkins.pipeline.DataDeploymentSupport

private DataDeploymentSupport support() {
    new DataDeploymentSupport(this)
}

def methodMissing(String name, Object args) {
    support().invokeMethod(name, args)
}
