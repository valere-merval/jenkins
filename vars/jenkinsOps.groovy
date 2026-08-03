import org.jenkins.pipeline.JenkinsOpsSupport

private JenkinsOpsSupport support() {
    new JenkinsOpsSupport(this)
}

def methodMissing(String name, Object args) {
    support().invokeMethod(name, args)
}
