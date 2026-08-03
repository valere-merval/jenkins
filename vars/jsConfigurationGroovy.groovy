import org.jenkins.pipeline.ConfigurationGroovySupport

private ConfigurationGroovySupport support() {
    new ConfigurationGroovySupport(this)
}

def methodMissing(String name, Object args) {
    support().invokeMethod(name, args)
}
