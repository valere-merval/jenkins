import org.jenkins.pipeline.EnvironmentControlSupport

private EnvironmentControlSupport support() {
    new EnvironmentControlSupport(this)
}

def methodMissing(String name, Object args) {
    support().invokeMethod(name, args)
}
