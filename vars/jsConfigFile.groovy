import org.jenkins.pipeline.ConfigFileSupport

private ConfigFileSupport support() {
    new ConfigFileSupport(this)
}

def methodMissing(String name, Object args) {
    support().invokeMethod(name, args)
}
